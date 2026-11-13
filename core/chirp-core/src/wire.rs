//! O que vai no fio (docs/PROTOCOLO.md): os frames do transporte e o conteúdo que vai
//! cifrado dentro da sessão, em Protobuf (`prost`, sem `.proto` nem `protoc`).
//!
//! Um frame é `tamanho (u32, big-endian) || Frame`, com no máximo `MAX_FRAME` bytes.
//! Nada aqui é confiável antes de decifrar: os tamanhos são conferidos antes de ler.

use prost::Message;
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};

use crate::error::{CoreError, CoreResult};

/// A versão do protocolo no fio (a mesma do `api::info`).
pub const VERSION: u32 = 1;

/// O maior frame aceito: 64 KiB (docs/PLANO.md, 6.4).
pub const MAX_FRAME: usize = 64 * 1024;

#[derive(Clone, PartialEq, Message)]
pub struct Frame {
    #[prost(uint32, tag = "1")]
    pub version: u32,
    #[prost(oneof = "Body", tags = "2, 3, 4, 5, 6, 7, 8, 9")]
    pub body: Option<Body>,
}

#[derive(Clone, PartialEq, prost::Oneof)]
pub enum Body {
    /// Quem leu o convite pede as prekeys, mostrando o token.
    #[prost(message, tag = "2")]
    BundleRequest(BundleRequest),
    /// As prekeys do convite, assinadas pela identidade de quem convidou.
    #[prost(message, tag = "3")]
    Bundle(Bundle),
    /// Uma mensagem que abre a sessão (PreKeySignalMessage do libsignal).
    #[prost(bytes, tag = "4")]
    PreKeyMessage(Vec<u8>),
    /// Uma mensagem de uma sessão aberta (SignalMessage).
    #[prost(bytes, tag = "5")]
    Message(Vec<u8>),
    /// O pedido foi recusado. Sem motivo: quem pergunta não aprende nada.
    #[prost(message, tag = "6")]
    Refused(Refused),
    /// A mensagem anterior foi decifrada e gravada (ou já estava): pode sair da
    /// caixa de saída. É o "entregue".
    #[prost(message, tag = "7")]
    Ack(Ack),
    /// Manda as fatias do arquivo a partir de `from` (fase 6). Só numa conexão de um
    /// contato, e só de um arquivo oferecido a ele.
    #[prost(message, tag = "8")]
    FileRequest(FileRequest),
    /// Uma fatia, cifrada como está guardada.
    #[prost(message, tag = "9")]
    FileChunk(FileChunk),
}

#[derive(Clone, PartialEq, Message)]
pub struct FileRequest {
    #[prost(bytes = "vec", tag = "1")]
    pub file_id: Vec<u8>,
    #[prost(uint32, tag = "2")]
    pub from: u32,
}

#[derive(Clone, PartialEq, Message)]
pub struct FileChunk {
    #[prost(uint32, tag = "1")]
    pub index: u32,
    #[prost(bytes = "vec", tag = "2")]
    pub data: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct BundleRequest {
    #[prost(bytes = "vec", tag = "1")]
    pub token: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Bundle {
    #[prost(uint32, tag = "1")]
    pub registration_id: u32,
    #[prost(uint32, tag = "2")]
    pub prekey_id: u32,
    #[prost(bytes = "vec", tag = "3")]
    pub prekey: Vec<u8>,
    #[prost(uint32, tag = "4")]
    pub signed_prekey_id: u32,
    #[prost(bytes = "vec", tag = "5")]
    pub signed_prekey: Vec<u8>,
    #[prost(bytes = "vec", tag = "6")]
    pub signed_prekey_signature: Vec<u8>,
    #[prost(uint32, tag = "7")]
    pub kyber_prekey_id: u32,
    #[prost(bytes = "vec", tag = "8")]
    pub kyber_prekey: Vec<u8>,
    #[prost(bytes = "vec", tag = "9")]
    pub kyber_prekey_signature: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Refused {}

#[derive(Clone, PartialEq, Message)]
pub struct Ack {}

/// O conteúdo decifrado.
#[derive(Clone, PartialEq, Message)]
pub struct Content {
    #[prost(bytes = "vec", tag = "1")]
    pub message_id: Vec<u8>,
    #[prost(
        oneof = "ContentBody",
        tags = "2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 17, 18, 20, 21, 22"
    )]
    pub body: Option<ContentBody>,
    /// O relógio de quem manda, em milissegundos: só para mostrar.
    #[prost(uint64, tag = "13")]
    pub sent_at: u64,
    /// O relógio de Lamport da conversa: a ordem das mensagens.
    #[prost(uint64, tag = "14")]
    pub lamport: u64,
    /// Até o próximo degrau de tamanho (docs/PLANO.md, 6.5).
    #[prost(bytes = "vec", tag = "15")]
    pub padding: Vec<u8>,
    /// O grupo da mensagem (fase 9, 16 bytes), ou vazio: a conversa a dois.
    #[prost(bytes = "vec", tag = "19")]
    pub group: Vec<u8>,
}

#[derive(Clone, PartialEq, prost::Oneof)]
pub enum ContentBody {
    /// A primeira mensagem de quem leu o convite.
    #[prost(message, tag = "2")]
    Hello(Hello),
    /// A resposta de quem convidou, que fecha o aperto de mão.
    #[prost(message, tag = "3")]
    Welcome(Welcome),
    #[prost(message, tag = "4")]
    Text(Text),
    /// "Li até aqui": os ids das mensagens lidas.
    #[prost(message, tag = "5")]
    Receipt(Receipt),
    #[prost(message, tag = "6")]
    Edit(Edit),
    /// Apagar para todos.
    #[prost(message, tag = "7")]
    Delete(Delete),
    #[prost(message, tag = "8")]
    Reaction(Reaction),
    /// Digitando agora.
    #[prost(message, tag = "9")]
    Typing(Typing),
    /// Chamar atenção (o "nudge" do MSN).
    #[prost(message, tag = "10")]
    Nudge(Nudge),
    /// O perfil mudou.
    #[prost(message, tag = "11")]
    Profile(PeerProfile),
    /// Os endereços mudaram (fase 5): só o `addrs` do `Peer` vale.
    #[prost(message, tag = "12")]
    Addrs(Peer),
    /// Um arquivo (fase 6): o que é e a chave; as fatias vêm depois, pedidas. (A 13,
    /// a 14 e a 15 são campos do `Content`.)
    #[prost(message, tag = "16")]
    File(FileOffer),
    /// A caixa postal de quem manda (fase 7): onde deixar o que não deu para entregar,
    /// e a ficha deste contato. Vazio: a caixa foi desligada.
    #[prost(message, tag = "17")]
    Mailbox(MailboxInfo),
    /// A foto do perfil de quem manda, ou vazio: não é mais para este contato.
    #[prost(message, tag = "18")]
    Photo(PeerPhoto),
    /// O grupo como o admin o deixou (fase 9): o nome e os membros, numa versão.
    #[prost(message, tag = "20")]
    Group(GroupUpdate),
    /// Quem manda saiu do grupo.
    #[prost(message, tag = "21")]
    GroupLeave(GroupLeave),
    /// Um convite para um membro que não é contato, pelo admin (fase 9, parte 2).
    #[prost(message, tag = "22")]
    GroupIntro(GroupIntro),
}

#[derive(Clone, PartialEq, Message)]
pub struct GroupIntro {
    #[prost(bytes = "vec", tag = "1")]
    pub group_id: Vec<u8>,
    /// Ao admin: para quem é o convite. Do admin: de quem é.
    #[prost(bytes = "vec", tag = "2")]
    pub member: Vec<u8>,
    /// O link do convite (`chirp://invite#...`).
    #[prost(string, tag = "3")]
    pub invite: String,
}

#[derive(Clone, PartialEq, Message)]
pub struct GroupUpdate {
    #[prost(bytes = "vec", tag = "1")]
    pub group_id: Vec<u8>,
    #[prost(string, tag = "2")]
    pub name: String,
    #[prost(uint64, tag = "3")]
    pub version: u64,
    /// A chave de identidade do admin (um dos membros).
    #[prost(bytes = "vec", tag = "4")]
    pub admin: Vec<u8>,
    /// Todos os membros, o admin e quem recebe também.
    #[prost(message, repeated, tag = "5")]
    pub members: Vec<GroupMember>,
}

#[derive(Clone, PartialEq, Message)]
pub struct GroupMember {
    #[prost(bytes = "vec", tag = "1")]
    pub identity_key: Vec<u8>,
    #[prost(bytes = "vec", tag = "2")]
    pub endpoint_id: Vec<u8>,
    #[prost(string, tag = "3")]
    pub name: String,
}

#[derive(Clone, PartialEq, Message)]
pub struct GroupLeave {
    #[prost(bytes = "vec", tag = "1")]
    pub group_id: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct PeerPhoto {
    /// Um JPEG quadrado de até 512 px (`photo::MAX_PHOTO`), ou vazio.
    #[prost(bytes = "vec", tag = "1")]
    pub jpeg: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct MailboxInfo {
    #[prost(bytes = "vec", tag = "1")]
    pub endpoint_id: Vec<u8>,
    #[prost(string, repeated, tag = "2")]
    pub addrs: Vec<String>,
    #[prost(bytes = "vec", tag = "3")]
    pub drop: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct FileOffer {
    #[prost(bytes = "vec", tag = "1")]
    pub file_id: Vec<u8>,
    #[prost(string, tag = "2")]
    pub name: String,
    #[prost(uint64, tag = "3")]
    pub size: u64,
    #[prost(string, tag = "4")]
    pub mime: String,
    /// O BLAKE3 do arquivo em claro.
    #[prost(bytes = "vec", tag = "5")]
    pub hash: Vec<u8>,
    /// A chave das fatias (AES-256-GCM).
    #[prost(bytes = "vec", tag = "6")]
    pub key: Vec<u8>,
    /// Uma miniatura em JPEG, feita por quem manda, ou vazio.
    #[prost(bytes = "vec", tag = "7")]
    pub thumbnail: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Text {
    #[prost(string, tag = "1")]
    pub text: String,
    /// A mensagem citada (o "responder"), ou vazio.
    #[prost(bytes = "vec", tag = "2")]
    pub reply_to: Vec<u8>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Receipt {
    #[prost(bytes = "vec", repeated, tag = "1")]
    pub read: Vec<Vec<u8>>,
    /// "Chegou": as que vieram pela caixa postal (fase 7), que não tiveram o `Ack`.
    #[prost(bytes = "vec", repeated, tag = "2")]
    pub delivered: Vec<Vec<u8>>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Edit {
    #[prost(bytes = "vec", tag = "1")]
    pub target: Vec<u8>,
    #[prost(string, tag = "2")]
    pub text: String,
}

#[derive(Clone, PartialEq, Message)]
pub struct Delete {
    #[prost(bytes = "vec", tag = "1")]
    pub target: Vec<u8>,
}

/// Uma reação: um dos tipos fixos (`messages::Reaction`); zero tira a reação.
#[derive(Clone, PartialEq, Message)]
pub struct Reaction {
    #[prost(bytes = "vec", tag = "1")]
    pub target: Vec<u8>,
    #[prost(uint32, tag = "2")]
    pub kind: u32,
}

#[derive(Clone, PartialEq, Message)]
pub struct Typing {}

#[derive(Clone, PartialEq, Message)]
pub struct Nudge {}

#[derive(Clone, PartialEq, Message)]
pub struct Hello {
    /// O token do convite, de novo, agora dentro da sessão: liga a sessão ao convite.
    #[prost(bytes = "vec", tag = "1")]
    pub token: Vec<u8>,
    #[prost(message, optional, tag = "2")]
    pub profile: Option<PeerProfile>,
    #[prost(message, optional, tag = "3")]
    pub peer: Option<Peer>,
    /// A caixa postal de quem leu o convite (fase 7), com a ficha de quem convidou:
    /// a resposta chega mesmo com ele desligado.
    #[prost(message, optional, tag = "4")]
    pub mailbox: Option<MailboxInfo>,
}

#[derive(Clone, PartialEq, Message)]
pub struct Welcome {
    #[prost(message, optional, tag = "1")]
    pub profile: Option<PeerProfile>,
    #[prost(message, optional, tag = "2")]
    pub peer: Option<Peer>,
}

#[derive(Clone, PartialEq, Message)]
pub struct PeerProfile {
    #[prost(string, tag = "1")]
    pub display_name: String,
    #[prost(uint32, tag = "2")]
    pub version: u32,
}

/// Como achar o aparelho na rede: o nó do transporte, os endereços de agora e a chave
/// dos tokens de descoberta. Só vai cifrado, só para o contato.
#[derive(Clone, PartialEq, Message)]
pub struct Peer {
    #[prost(bytes = "vec", tag = "1")]
    pub endpoint_id: Vec<u8>,
    #[prost(string, repeated, tag = "2")]
    pub addrs: Vec<String>,
    #[prost(bytes = "vec", tag = "3")]
    pub discovery_key: Vec<u8>,
}

/// Os degraus do preenchimento: o tamanho cifrado não diz "curta" ou "foto".
const PAD_STEPS: [usize; 5] = [256, 1024, 4096, 16 * 1024, 60 * 1024];

impl Content {
    /// Codifica com o preenchimento até o próximo degrau.
    pub fn encode_padded(mut self) -> Vec<u8> {
        self.padding.clear();
        let bare = self.encoded_len();
        // O campo do preenchimento custa a tag (1 byte) e o tamanho (até 3 bytes).
        let Some(target) = PAD_STEPS.iter().copied().find(|step| *step >= bare + 4) else {
            return self.encode_to_vec();
        };
        let mut fill = target - bare - 4;
        // Acerta o byte que o tamanho em varint pode ganhar ou perder.
        for _ in 0..4 {
            self.padding = vec![0; fill];
            let len = self.encoded_len();
            if len == target {
                break;
            }
            fill = (fill + target).saturating_sub(len);
        }
        self.encode_to_vec()
    }
}

pub fn frame(body: Body) -> Frame {
    Frame {
        version: VERSION,
        body: Some(body),
    }
}

pub async fn write_frame<W: AsyncWrite + Unpin>(out: &mut W, frame: &Frame) -> CoreResult<()> {
    let bytes = frame.encode_to_vec();
    if bytes.len() > MAX_FRAME {
        return Err(CoreError::Protocol);
    }
    out.write_u32(bytes.len() as u32)
        .await
        .map_err(|_| CoreError::Unreachable)?;
    out.write_all(&bytes)
        .await
        .map_err(|_| CoreError::Unreachable)?;
    Ok(())
}

/// Lê um frame. O tamanho é conferido antes de alocar, e uma versão diferente é
/// recusada.
pub async fn read_frame<R: AsyncRead + Unpin>(input: &mut R) -> CoreResult<Body> {
    let len = input.read_u32().await.map_err(|_| CoreError::Unreachable)? as usize;
    if len > MAX_FRAME {
        return Err(CoreError::Protocol);
    }
    let mut bytes = vec![0u8; len];
    input
        .read_exact(&mut bytes)
        .await
        .map_err(|_| CoreError::Unreachable)?;
    decode_frame(&bytes)
}

pub fn decode_frame(bytes: &[u8]) -> CoreResult<Body> {
    let frame = Frame::decode(bytes).map_err(|_| CoreError::Protocol)?;
    if frame.version != VERSION {
        return Err(CoreError::Protocol);
    }
    frame.body.ok_or(CoreError::Protocol)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padding_lands_on_a_step() {
        for name_len in [0, 10, 200, 900, 3000] {
            let content = Content {
                message_id: vec![7; 16],
                body: Some(ContentBody::Welcome(Welcome {
                    profile: Some(PeerProfile {
                        display_name: "a".repeat(name_len),
                        version: 1,
                    }),
                    peer: None,
                })),
                sent_at: 1,
                lamport: 1,
                padding: vec![],
                group: vec![],
            };
            let len = content.encode_padded().len();
            assert!(PAD_STEPS.contains(&len), "{name_len} -> {len}");
        }
    }

    #[tokio::test]
    async fn frames_round_trip() {
        let (mut a, mut b) = tokio::io::duplex(1024);
        let sent = frame(Body::BundleRequest(BundleRequest {
            token: vec![1, 2, 3],
        }));
        write_frame(&mut a, &sent).await.unwrap();
        assert_eq!(read_frame(&mut b).await.unwrap(), sent.body.unwrap());
    }

    #[tokio::test]
    async fn an_oversized_frame_is_refused_before_reading() {
        let (mut a, mut b) = tokio::io::duplex(64);
        a.write_u32((MAX_FRAME + 1) as u32).await.unwrap();
        assert_eq!(read_frame(&mut b).await, Err(CoreError::Protocol));
    }

    #[test]
    fn garbage_and_other_versions_are_refused() {
        assert_eq!(decode_frame(&[0xff, 0xff, 0xff]), Err(CoreError::Protocol));
        let other = Frame {
            version: VERSION + 1,
            body: Some(Body::Refused(Refused {})),
        };
        assert_eq!(
            decode_frame(&other.encode_to_vec()),
            Err(CoreError::Protocol)
        );
        let empty = Frame {
            version: VERSION,
            body: None,
        };
        assert_eq!(
            decode_frame(&empty.encode_to_vec()),
            Err(CoreError::Protocol)
        );
    }
}
