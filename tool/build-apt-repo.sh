#!/bin/bash
# Monta o repositório APT em arquivos estáticos, a partir dos .deb, e assina os
# índices com a chave que estiver no gpg. O CI publica o resultado no GitHub Pages.
# Uso: tool/build-apt-repo.sh <pasta de saída> <arquivo.deb>...
set -e

OUT="$1"
shift
[ -n "$OUT" ] && [ $# -gt 0 ] || {
    echo "Uso: $0 <pasta de saída> <arquivo.deb>..." >&2
    exit 1
}

POOL="$OUT/pool/main/p/psito-chirp"
DIST="$OUT/dists/stable"
BINARY="$DIST/main/binary-amd64"
mkdir -p "$POOL" "$BINARY"
cp "$@" "$POOL/"

(cd "$OUT" && apt-ftparchive packages pool) > "$BINARY/Packages"
gzip -9nkf "$BINARY/Packages"

apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="Psito Chirp" \
    -o APT::FTPArchive::Release::Label="Psito Chirp" \
    -o APT::FTPArchive::Release::Suite=stable \
    -o APT::FTPArchive::Release::Codename=stable \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    release "$DIST" > "$DIST/Release.tmp"
mv "$DIST/Release.tmp" "$DIST/Release"

gpg --batch --yes --clearsign -o "$DIST/InRelease" "$DIST/Release"
gpg --batch --yes --armor --detach-sign -o "$DIST/Release.gpg" "$DIST/Release"
gpg --batch --yes --armor --export > "$OUT/psito-chirp.asc"
