#![cfg_attr(not(target_os = "android"), allow(dead_code))]
//! Um soquete que só sabe ler e escrever bloqueando (o `BluetoothSocket` do Android,
//! pelo JNI) virando um [`Link`]: duas threads levam os bytes entre ele e um
//! `tokio::io::duplex`. Fechar de qualquer lado fecha o outro.

use std::sync::Arc;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::runtime::Handle;

use super::Link;

/// O que cabe de uma vez em cada sentido.
const CHUNK: usize = 4096;

pub trait BlockingSocket: Send + Sync + 'static {
    /// Lê até `buf.len()` bytes; `None` é o fim (ou um erro).
    fn read(&self, buf: &mut [u8]) -> Option<usize>;
    /// Escreve tudo; `false` é um erro.
    fn write(&self, data: &[u8]) -> bool;
    /// Fecha (pode ser chamado mais de uma vez, e destrava um `read` parado).
    fn close(&self);
}

/// O soquete como um [`Link`], no `runtime` dado.
pub fn link(socket: Arc<dyn BlockingSocket>, runtime: Handle) -> Link {
    let (ours, theirs) = tokio::io::duplex(4 * CHUNK);
    let (mut from_link, mut to_link) = tokio::io::split(theirs);

    // Do soquete para o link.
    let reader = socket.clone();
    let handle = runtime.clone();
    std::thread::spawn(move || {
        let mut buf = vec![0u8; CHUNK];
        while let Some(n) = reader.read(&mut buf).filter(|n| *n > 0) {
            if handle.block_on(to_link.write_all(&buf[..n])).is_err() {
                break;
            }
        }
        let _ = handle.block_on(to_link.shutdown());
        reader.close();
    });

    // Do link para o soquete.
    std::thread::spawn(move || {
        let mut buf = vec![0u8; CHUNK];
        loop {
            match runtime.block_on(from_link.read(&mut buf)) {
                Ok(n) if n > 0 && socket.write(&buf[..n]) => {}
                _ => break,
            }
        }
        socket.close();
    });

    Box::new(ours)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::mpsc;
    use std::sync::Mutex;

    /// Um soquete de mentira: o que chega vem de um canal, e o que sai vai para outro.
    struct Fake {
        incoming: Mutex<mpsc::Receiver<Vec<u8>>>,
        outgoing: Mutex<Option<mpsc::Sender<Vec<u8>>>>,
        closed: Mutex<bool>,
    }

    impl BlockingSocket for Fake {
        fn read(&self, buf: &mut [u8]) -> Option<usize> {
            let data = self.incoming.lock().unwrap().recv().ok()?;
            buf[..data.len()].copy_from_slice(&data);
            Some(data.len())
        }
        fn write(&self, data: &[u8]) -> bool {
            match self.outgoing.lock().unwrap().as_ref() {
                Some(tx) => tx.send(data.to_vec()).is_ok(),
                None => false,
            }
        }
        fn close(&self) {
            *self.closed.lock().unwrap() = true;
            self.outgoing.lock().unwrap().take();
        }
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn bytes_go_both_ways_and_closing_ends_the_link() {
        let (to_socket, incoming) = mpsc::channel();
        let (outgoing, from_socket) = mpsc::channel();
        let fake = Arc::new(Fake {
            incoming: Mutex::new(incoming),
            outgoing: Mutex::new(Some(outgoing)),
            closed: Mutex::new(false),
        });
        let mut link = link(fake.clone(), Handle::current());

        to_socket.send(b"piu".to_vec()).unwrap();
        let mut got = [0u8; 3];
        link.read_exact(&mut got).await.unwrap();
        assert_eq!(&got, b"piu");

        link.write_all(b"piu piu").await.unwrap();
        link.flush().await.unwrap();
        let sent = tokio::task::spawn_blocking(move || from_socket.recv().unwrap())
            .await
            .unwrap();
        assert_eq!(sent, b"piu piu");

        // O outro lado fechou: o link chega ao fim.
        drop(to_socket);
        let mut rest = Vec::new();
        link.read_to_end(&mut rest).await.unwrap();
        assert!(rest.is_empty());
        assert!(*fake.closed.lock().unwrap());
    }
}
