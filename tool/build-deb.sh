#!/bin/bash
# Compila e monta o pacote .deb, sem sudo. Leva o bundle inteiro (o núcleo em Rust já
# vem com o SQLCipher e o OpenSSL dentro) e pega do sistema o GTK, o libsecret (o
# chaveiro, onde fica a chave do banco) e o EGL e o GLES, que o Flutter abre na hora
# de desenhar e o ldd não mostra. O binário usa um símbolo da GLib 2.80, que o Ubuntu
# 24.04 do CI tem e o Debian 12 não.
# Uso: tool/build-deb.sh [pasta de saída, padrão build/deb] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="${1:-build/deb}"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
NAME=psito-chirp

[ "$2" = "--no-build" ] || flutter build linux --release

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/DEBIAN"
tool/stage-package.sh "$ROOT"

cat > "$ROOT/DEBIAN/control" <<CONTROL
Package: $NAME
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Maintainer: Francisco Souza <francisceioseph@users.noreply.github.com>
Homepage: https://github.com/francisceioseph/chirp
Installed-Size: $(du -sk "$ROOT/usr" | cut -f1)
Depends: libc6 (>= 2.38), libgtk-3-0 | libgtk-3-0t64, libglib2.0-0t64 (>= 2.80) | libglib2.0-0 (>= 2.80), libsecret-1-0, libegl1, libgles2
Recommends: libgl1-mesa-dri, gnome-keyring | kwalletmanager | keepassxc
Description: Private messenger with no servers in the middle
 Conversations go straight from one device to the other, over the local
 network or the internet, encrypted end to end with the Signal protocol.
 No accounts, no phone numbers, no logs and no telemetry.
CONTROL

mkdir -p "$OUT"
DEB="$OUT/${NAME}_${VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build "$ROOT" "$DEB" >/dev/null
echo "$DEB"
