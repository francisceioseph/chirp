#!/bin/bash
# Gera o pacote do AUR (psito-chirp-bin) de uma versão já publicada: o PKGBUILD e o
# .SRCINFO, com o .deb da release como fonte. Quem envia ao AUR é quem mantém o pacote,
# com a própria conta.
# Uso: tool/build-aur.sh <pasta de saída> [versão, padrão a do pubspec.yaml]
set -e

cd "$(dirname "$0")/.."

OUT="${1:?uso: tool/build-aur.sh <pasta de saída> [versão]}"
VERSION="${2:-$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)}"
REPO=https://github.com/francisceioseph/chirp
DESC='Private messenger with no servers in the middle'
SOURCE="psito-chirp-$VERSION.deb::$REPO/releases/download/v$VERSION/psito-chirp_${VERSION}_amd64.deb"
SHA="$(curl -fsSL "${SOURCE#*::}" | sha256sum | cut -d' ' -f1)"
DEPENDS=(gtk3 'glib2>=2.80' libsecret libglvnd opengl-driver hicolor-icon-theme)

mkdir -p "$OUT"
cat > "$OUT/PKGBUILD" <<PKGBUILD
# Maintainer: Francisco Souza <francisceioseph at users dot noreply dot github dot com>
pkgname=psito-chirp-bin
pkgver=$VERSION
pkgrel=1
pkgdesc='$DESC'
arch=('x86_64')
url='$REPO'
license=('AGPL-3.0-only')
depends=($(printf "'%s' " "${DEPENDS[@]}" | sed 's/ $//'))
provides=('psito-chirp')
conflicts=('psito-chirp')
options=('!strip' '!debug')
source=("$SOURCE")
sha256sums=('$SHA')

package() {
  bsdtar -xf data.tar.* -C "\$pkgdir"
}
PKGBUILD

{
    printf 'pkgbase = psito-chirp-bin\n'
    printf '\tpkgdesc = %s\n\tpkgver = %s\n\tpkgrel = 1\n\turl = %s\n\tarch = x86_64\n\tlicense = AGPL-3.0-only\n' "$DESC" "$VERSION" "$REPO"
    printf '\tdepends = %s\n' "${DEPENDS[@]}"
    printf '\tprovides = psito-chirp\n\tconflicts = psito-chirp\n\toptions = !strip\n\toptions = !debug\n'
    printf '\tsource = %s\n\tsha256sums = %s\n\npkgname = psito-chirp-bin\n' "$SOURCE" "$SHA"
} > "$OUT/.SRCINFO"

# O AUR pede uma licença para os arquivos do pacote, e recomenda a 0BSD
cat > "$OUT/LICENSE" <<'LICENSE'
Copyright (C) 2026 Francisco Souza

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
LICENSE
