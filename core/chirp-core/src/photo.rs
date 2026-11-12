//! A foto do perfil: quadrada, até 512 px, codificada de novo no aparelho (sem EXIF
//! nem nada além dos pixels), e mostrada só a quem quem usa escolher: ninguém, todos
//! os contatos ou só os marcados.
//!
//! A foto vai pela sessão, como uma mensagem (o `Photo`, conteúdo 18): passa pela
//! caixa postal e não pede os dois online. Tirar alguém manda uma foto vazia, e o app
//! dele apaga a que tinha; o que ele já guardou fora do app não volta.

use rusqlite::{Connection, OptionalExtension};
use sha2::{Digest, Sha256};

use crate::error::{CoreError, CoreResult};

/// O lado da foto, em pixels.
pub const SIDE: u32 = 512;
/// O maior JPEG de uma foto: cabe numa mensagem com folga.
pub const MAX_PHOTO: usize = 48 * 1024;
/// O maior arquivo que se escolhe para virar foto.
const MAX_SOURCE: usize = 64 << 20;

/// Quem vê a foto.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Visibility {
    Nobody = 0,
    /// Todos os contatos.
    Everyone = 1,
    /// Só os contatos marcados (`photo_allowed`).
    Chosen = 2,
}

impl Visibility {
    fn from_i64(value: i64) -> Self {
        match value {
            0 => Self::Nobody,
            2 => Self::Chosen,
            _ => Self::Everyone,
        }
    }
}

/// A foto deste aparelho, se houver, e quem vê.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Own {
    pub jpeg: Option<Vec<u8>>,
    pub hash: Option<Vec<u8>>,
    pub visibility: Visibility,
}

/// Uma imagem escolhida vira a foto: o centro quadrado, até 512 px, em JPEG, com a
/// rotação do EXIF aplicada e nenhum metadado.
pub fn prepare(bytes: &[u8]) -> CoreResult<Vec<u8>> {
    if bytes.len() > MAX_SOURCE {
        return Err(CoreError::InvalidFile);
    }
    let image = crate::files::decode(bytes)?;
    let side = image.width().min(image.height()).clamp(1, SIDE);
    for (side, quality) in [
        (side, 85),
        (side, 75),
        (side, 65),
        (side.min(384), 65),
        (side.min(256), 60),
    ] {
        let square = image.resize_to_fill(side, side, image::imageops::FilterType::Lanczos3);
        let jpeg = crate::files::jpeg(&square, quality)?;
        if jpeg.len() <= MAX_PHOTO {
            return Ok(jpeg);
        }
    }
    Err(CoreError::InvalidFile)
}

/// A foto que um contato mandou serve: um JPEG inteiro que se decodifica, no tamanho,
/// quase quadrado e até 1024 px.
pub fn check(jpeg: &[u8]) -> bool {
    // O começo e o fim do JPEG: o decodificador aceita um cortado, e enche de cinza.
    if jpeg.len() > MAX_PHOTO || !jpeg.starts_with(&[0xFF, 0xD8]) || !jpeg.ends_with(&[0xFF, 0xD9])
    {
        return false;
    }
    let Ok(image) = crate::files::decode(jpeg) else {
        return false;
    };
    let (w, h) = (image.width(), image.height());
    w > 0 && h > 0 && w <= 1024 && h <= 1024 && w.abs_diff(h) <= w.max(h) / 10
}

fn hash(jpeg: &[u8]) -> Vec<u8> {
    Sha256::digest(jpeg).to_vec()
}

pub fn own(conn: &Connection) -> CoreResult<Own> {
    Ok(conn.query_row(
        "SELECT jpeg, hash, visibility FROM photo WHERE id = 1",
        [],
        |r| {
            Ok(Own {
                jpeg: r.get(0)?,
                hash: r.get(1)?,
                visibility: Visibility::from_i64(r.get(2)?),
            })
        },
    )?)
}

/// Troca (ou tira, com `None`) a foto deste aparelho.
pub fn set_own(conn: &Connection, jpeg: Option<&[u8]>) -> CoreResult<()> {
    conn.execute(
        "UPDATE photo SET jpeg = ?1, hash = ?2 WHERE id = 1",
        (jpeg, jpeg.map(hash)),
    )?;
    Ok(())
}

pub fn set_visibility(conn: &Connection, visibility: Visibility) -> CoreResult<()> {
    conn.execute(
        "UPDATE photo SET visibility = ?1 WHERE id = 1",
        [visibility as i64],
    )?;
    Ok(())
}

/// Marca (ou desmarca) um contato entre os que veem a foto no modo `Chosen`.
pub fn set_allowed(conn: &Connection, contact_id: i64, allowed: bool) -> CoreResult<()> {
    let changed = conn.execute(
        "UPDATE contacts SET photo_allowed = ?2 WHERE id = ?1",
        (contact_id, allowed),
    )?;
    if changed == 0 {
        return Err(CoreError::UnknownContact);
    }
    Ok(())
}

/// O contato deve ter a foto agora?
pub fn visible_to(own: &Own, allowed: bool) -> bool {
    own.jpeg.is_some()
        && match own.visibility {
            Visibility::Nobody => false,
            Visibility::Everyone => true,
            Visibility::Chosen => allowed,
        }
}

/// O que o contato recebeu por último: nada (nunca mandou), a falta de foto (vazio) ou
/// o hash da foto.
pub fn sent(conn: &Connection, contact_id: i64) -> CoreResult<Option<Vec<u8>>> {
    Ok(conn
        .query_row(
            "SELECT photo_sent FROM contacts WHERE id = ?1",
            [contact_id],
            |r| r.get::<_, Option<Vec<u8>>>(0),
        )
        .optional()?
        .flatten())
}

pub fn set_sent(conn: &Connection, contact_id: i64, sent: &[u8]) -> CoreResult<()> {
    conn.execute(
        "UPDATE contacts SET photo_sent = ?2 WHERE id = ?1",
        (contact_id, sent),
    )?;
    Ok(())
}

/// A foto que o contato mandou (ou a falta dela). Devolve se mudou.
pub fn set_theirs(conn: &Connection, contact_id: i64, jpeg: Option<&[u8]>) -> CoreResult<bool> {
    let changed = conn.execute(
        "UPDATE contacts SET photo = ?2 WHERE id = ?1 AND photo IS NOT ?2",
        (contact_id, jpeg),
    )?;
    Ok(changed > 0)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn png(w: u32, h: u32) -> Vec<u8> {
        let image = image::DynamicImage::new_rgb8(w, h);
        let mut out = Vec::new();
        image
            .write_to(&mut std::io::Cursor::new(&mut out), image::ImageFormat::Png)
            .unwrap();
        out
    }

    #[test]
    fn a_picture_becomes_a_small_square_jpeg() {
        let jpeg = prepare(&png(1200, 800)).unwrap();
        assert!(jpeg.len() <= MAX_PHOTO);
        let image = crate::files::decode(&jpeg).unwrap();
        assert_eq!((image.width(), image.height()), (SIDE, SIDE));
        assert!(check(&jpeg));
        // Pequena, fica no tamanho dela.
        let small = crate::files::decode(&prepare(&png(100, 300)).unwrap()).unwrap();
        assert_eq!((small.width(), small.height()), (100, 100));
        assert!(prepare(b"not an image").is_err());
    }

    #[test]
    fn photos_from_contacts_are_checked() {
        assert!(!check(b""));
        assert!(!check(&png(64, 64)), "só JPEG");
        let wide = crate::files::jpeg(&image::DynamicImage::new_rgb8(400, 100), 80).unwrap();
        assert!(!check(&wide), "quase quadrada");
        let mut cut = prepare(&png(300, 300)).unwrap();
        cut.truncate(cut.len() / 2);
        assert!(!check(&cut));
    }

    #[test]
    fn who_sees_it() {
        let mut own = Own {
            jpeg: Some(vec![1]),
            hash: Some(vec![2]),
            visibility: Visibility::Everyone,
        };
        assert!(visible_to(&own, false));
        own.visibility = Visibility::Chosen;
        assert!(!visible_to(&own, false) && visible_to(&own, true));
        own.visibility = Visibility::Nobody;
        assert!(!visible_to(&own, true));
        own.visibility = Visibility::Everyone;
        own.jpeg = None;
        assert!(!visible_to(&own, true));
    }
}
