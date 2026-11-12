#!/bin/bash
# Compila e monta o pacote .deb da caixa postal (chirp-mailbox), sem sudo: o binário,
# a unidade do systemd (ligada na instalação) e nada mais. A dependência da glibc sai
# da maior versão que o binário pede.
# Uso: tool/build-mailbox-deb.sh [pasta de saída, padrão build/deb] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="${1:-build/deb}"
VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' core/chirp-mailbox/Cargo.toml | head -1)"
NAME=chirp-mailbox
BIN=core/target/release/chirp-mailbox

[ "$2" = "--no-build" ] || cargo build --release --manifest-path core/Cargo.toml \
  -p chirp_mailbox --bin chirp-mailbox

GLIBC="$(objdump -T "$BIN" | grep -o 'GLIBC_[0-9.]*' | sed 's/GLIBC_//' | sort -V | tail -1)"

ROOT="$(mktemp -d)"
trap 'rm -rf "$ROOT"' EXIT
chmod 755 "$ROOT"
install -Dm755 "$BIN" "$ROOT/usr/bin/chirp-mailbox"
install -Dm644 core/chirp-mailbox/packaging/chirp-mailbox.service \
  "$ROOT/usr/lib/systemd/system/chirp-mailbox.service"
install -Dm644 LICENSE "$ROOT/usr/share/doc/$NAME/copyright"
mkdir -p "$ROOT/DEBIAN"

cat > "$ROOT/DEBIAN/control" <<CONTROL
Package: $NAME
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Maintainer: Francisco Souza <francisceioseph@users.noreply.github.com>
Homepage: https://github.com/francisceioseph/chirp
Installed-Size: $(du -sk "$ROOT/usr" | cut -f1)
Depends: libc6 (>= $GLIBC)
Recommends: systemd
Description: Mailbox for Psito Chirp
 Keeps messages that contacts send while your device is off, already encrypted
 end to end, until Chirp comes online and fetches them. It sees who leaves
 something and when, never the content. Link it to the app with
 "sudo chirp-mailbox pair --data /var/lib/chirp-mailbox".
CONTROL

cat > "$ROOT/DEBIAN/postinst" <<'SCRIPT'
#!/bin/sh
set -e
if [ "$1" = configure ] && [ -d /run/systemd/system ]; then
  systemctl daemon-reload
  systemctl enable chirp-mailbox.service >/dev/null 2>&1 || true
  systemctl restart chirp-mailbox.service || true
fi
SCRIPT

cat > "$ROOT/DEBIAN/prerm" <<'SCRIPT'
#!/bin/sh
set -e
if [ "$1" = remove ] && [ -d /run/systemd/system ]; then
  systemctl disable --now chirp-mailbox.service >/dev/null 2>&1 || true
fi
SCRIPT

cat > "$ROOT/DEBIAN/postrm" <<'SCRIPT'
#!/bin/sh
set -e
[ -d /run/systemd/system ] && systemctl daemon-reload || true
# Apagar de vez leva também o que estava guardado.
if [ "$1" = purge ]; then
  rm -rf /var/lib/private/chirp-mailbox /var/lib/chirp-mailbox
fi
SCRIPT
chmod 755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/prerm" "$ROOT/DEBIAN/postrm"

mkdir -p "$OUT"
DEB="$OUT/${NAME}_${VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build "$ROOT" "$DEB" >/dev/null
echo "$DEB"
