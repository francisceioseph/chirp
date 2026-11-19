//! O rádio no Android: o `ChirpBle` do app (Kotlin), pelo JNI. Ele anuncia, procura e
//! abre os canais L2CAP (`listenUsingInsecureL2capChannel`, Android 10 ou mais novo);
//! aqui, cada canal vira um [`Link`] pelo [`blocking`](super::blocking). O app chama o
//! `nativeInit` ao abrir (é por ele que o núcleo acha a classe e a JVM), e avisa pelo
//! `onIncoming` e pelo `onSighting`. Sem a classe, sem a licença ou com o Bluetooth
//! desligado, o nó segue sem Bluetooth.
//!
//! "Inseguro" é o nome do Android para o canal sem o pareamento do Bluetooth: quem
//! protege é o Noise ([`secure`](super::secure)), como no Linux.

use std::sync::{Arc, Mutex, OnceLock};

use async_trait::async_trait;
use jni::objects::{GlobalRef, JByteArray, JClass, JString, JValue};
use jni::{JNIEnv, JavaVM};
use tokio::runtime::Handle;
use tokio::sync::mpsc;

use super::blocking::{self, BlockingSocket};
use super::{Link, Radio, Sighting};
use crate::error::{CoreError, CoreResult};

/// A JVM e a classe `org.psito.chirp.ChirpBle`, guardadas no `nativeInit` (numa thread
/// do Java, a única em que a classe do app aparece).
static JAVA: OnceLock<(JavaVM, GlobalRef)> = OnceLock::new();

/// Para onde vão os avisos do app.
struct Hub {
    runtime: Handle,
    incoming: Option<mpsc::Sender<Link>>,
    sightings: Option<mpsc::Sender<Sighting>>,
}

static HUB: Mutex<Option<Hub>> = Mutex::new(None);

/// Chama um método estático do `ChirpBle`, numa thread presa à JVM (para sempre: as
/// threads do tokio e as dos soquetes voltam muitas vezes).
fn call<T>(f: impl FnOnce(&mut JNIEnv, &JClass) -> jni::errors::Result<T>) -> Option<T> {
    let (vm, class) = JAVA.get()?;
    let mut env = vm.attach_current_thread_as_daemon().ok()?;
    let class: &JClass = class.as_obj().into();
    match f(&mut env, class) {
        Ok(value) => Some(value),
        Err(_) => {
            // Uma exceção do Java fica pendente e quebraria a próxima chamada.
            let _ = env.exception_clear();
            None
        }
    }
}

fn call_bool(name: &str) -> bool {
    call(|env, class| env.call_static_method(class, name, "()Z", &[])?.z()).unwrap_or(false)
}

/// Um `BluetoothSocket` guardado no app, pelo número.
struct Socket(i32);

impl BlockingSocket for Socket {
    fn read(&self, buf: &mut [u8]) -> Option<usize> {
        call(|env, class| {
            let array = env.new_byte_array(buf.len() as i32)?;
            let n = env
                .call_static_method(
                    class,
                    "read",
                    "(I[B)I",
                    &[JValue::Int(self.0), JValue::from(&array)],
                )?
                .i()?;
            if n <= 0 {
                return Ok(None);
            }
            let n = (n as usize).min(buf.len());
            let mut signed = vec![0i8; n];
            env.get_byte_array_region(&array, 0, &mut signed)?;
            for (to, from) in buf.iter_mut().zip(signed) {
                *to = from as u8;
            }
            Ok(Some(n))
        })
        .flatten()
    }

    fn write(&self, data: &[u8]) -> bool {
        call(|env, class| {
            let array = env.byte_array_from_slice(data)?;
            env.call_static_method(
                class,
                "write",
                "(I[B)Z",
                &[JValue::Int(self.0), JValue::from(&array)],
            )?
            .z()
        })
        .unwrap_or(false)
    }

    fn close(&self) {
        let _ = call(|env, class| {
            env.call_static_method(class, "close", "(I)V", &[JValue::Int(self.0)])
                .map(|_| ())
        });
    }
}

pub struct Android;

impl Android {
    /// O rádio do app, se o Bluetooth está ligado e com a licença.
    pub fn open() -> CoreResult<Self> {
        if call_bool("available") {
            Ok(Self)
        } else {
            Err(CoreError::Unreachable)
        }
    }
}

fn hub<T>(f: impl FnOnce(&mut Hub) -> T) -> T {
    let mut slot = HUB.lock().unwrap_or_else(|e| e.into_inner());
    let hub = slot.get_or_insert_with(|| Hub {
        runtime: Handle::current(),
        incoming: None,
        sightings: None,
    });
    f(hub)
}

#[async_trait]
impl Radio for Android {
    async fn listen(&self) -> CoreResult<(u16, mpsc::Receiver<Link>)> {
        let (tx, rx) = mpsc::channel(8);
        hub(|h| {
            h.runtime = Handle::current();
            h.incoming = Some(tx);
        });
        let psm = call(|env, class| env.call_static_method(class, "listen", "()I", &[])?.i())
            .unwrap_or(-1);
        u16::try_from(psm)
            .ok()
            .filter(|p| *p != 0)
            .map(|p| (p, rx))
            .ok_or(CoreError::Unreachable)
    }

    async fn advertise(&self, data: Vec<u8>) -> CoreResult<()> {
        call(|env, class| {
            let array = env.byte_array_from_slice(&data)?;
            env.call_static_method(class, "advertise", "([B)Z", &[JValue::from(&array)])?
                .z()
        })
        .filter(|ok| *ok)
        .map(|_| ())
        .ok_or(CoreError::Unreachable)
    }

    async fn scan(&self) -> CoreResult<mpsc::Receiver<Sighting>> {
        let (tx, rx) = mpsc::channel(64);
        hub(|h| h.sightings = Some(tx));
        if call_bool("scan") {
            Ok(rx)
        } else {
            Err(CoreError::Unreachable)
        }
    }

    async fn connect(&self, peer: &str, psm: u16) -> CoreResult<Link> {
        let peer = peer.to_owned();
        // O `connect` do Android bloqueia até o outro aceitar (ou desistir).
        let id = tokio::task::spawn_blocking(move || {
            call(|env, class| {
                let address = env.new_string(&peer)?;
                env.call_static_method(
                    class,
                    "connect",
                    "(Ljava/lang/String;I)I",
                    &[JValue::from(&address), JValue::Int(i32::from(psm))],
                )?
                .i()
            })
        })
        .await
        .ok()
        .flatten()
        .filter(|id| *id > 0)
        .ok_or(CoreError::Unreachable)?;
        Ok(blocking::link(Arc::new(Socket(id)), Handle::current()))
    }

    async fn stop(&self) {
        hub(|h| {
            h.incoming = None;
            h.sightings = None;
        });
        let _ = call(|env, class| {
            env.call_static_method(class, "stop", "()V", &[])
                .map(|_| ())
        });
    }
}

// ---------------------------------------------------------------- o que o app chama
//
// O JNI acha estas funções pelo nome (`Java_<pacote>_<classe>_<método>`), então elas
// precisam do `no_mangle`, que o crate só deixa aqui. Os nomes são do Chirp e não
// colidem com os de outra biblioteca.

/// O app abriu: guarda a JVM e a classe.
#[allow(unsafe_code)]
#[no_mangle]
pub extern "system" fn Java_org_psito_chirp_ChirpBle_nativeInit<'local>(
    env: JNIEnv<'local>,
    class: JClass<'local>,
) {
    if JAVA.get().is_some() {
        return;
    }
    let (Ok(vm), Ok(class)) = (env.get_java_vm(), env.new_global_ref(class)) else {
        return;
    };
    let _ = JAVA.set((vm, class));
}

/// Chegou uma conexão no canal (o número do soquete).
#[allow(unsafe_code)]
#[no_mangle]
pub extern "system" fn Java_org_psito_chirp_ChirpBle_onIncoming<'local>(
    _env: JNIEnv<'local>,
    _class: JClass<'local>,
    id: i32,
) {
    let slot = HUB.lock().unwrap_or_else(|e| e.into_inner());
    let accepted = slot.as_ref().and_then(|h| {
        let tx = h.incoming.as_ref()?;
        let link = blocking::link(Arc::new(Socket(id)), h.runtime.clone());
        tx.try_send(link).ok()
    });
    drop(slot);
    if accepted.is_none() {
        Socket(id).close();
    }
}

/// Um anúncio do Chirp foi visto: o endereço e os dados de serviço.
#[allow(unsafe_code)]
#[no_mangle]
pub extern "system" fn Java_org_psito_chirp_ChirpBle_onSighting<'local>(
    mut env: JNIEnv<'local>,
    _class: JClass<'local>,
    address: JString<'local>,
    data: JByteArray<'local>,
) {
    let (Ok(peer), Ok(data)) = (env.get_string(&address), env.convert_byte_array(&data)) else {
        let _ = env.exception_clear();
        return;
    };
    let slot = HUB.lock().unwrap_or_else(|e| e.into_inner());
    if let Some(tx) = slot.as_ref().and_then(|h| h.sightings.as_ref()) {
        let _ = tx.try_send(Sighting {
            peer: peer.into(),
            data,
        });
    }
}
