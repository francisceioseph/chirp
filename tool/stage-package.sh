#!/bin/bash
# Monta em <raiz> os arquivos que todo pacote do Linux instala, a partir do bundle de
# release. Quem chama é o build-deb.sh e o build-rpm.sh.
# Uso: tool/stage-package.sh <raiz>
set -e

cd "$(dirname "$0")/.."

ROOT="${1:?uso: tool/stage-package.sh <raiz>}"
ID=org.psito.chirp
NAME=psito-chirp
BUNDLE=build/linux/x64/release/bundle

mkdir -p "$ROOT/usr/bin" "$ROOT/usr/lib/$NAME" \
    "$ROOT/usr/share/applications" \
    "$ROOT/usr/share/metainfo" \
    "$ROOT/usr/share/icons/hicolor/scalable/apps" \
    "$ROOT/usr/share/doc/$NAME"

cp -r "$BUNDLE/." "$ROOT/usr/lib/$NAME/"
ln -s "../lib/$NAME/psito_chirp" "$ROOT/usr/bin/$NAME"
cp "linux/packaging/$ID.desktop" "$ROOT/usr/share/applications/"
cp "linux/packaging/$ID.metainfo.xml" "$ROOT/usr/share/metainfo/"
cp assets/images/chirp_icon.svg "$ROOT/usr/share/icons/hicolor/scalable/apps/$ID.svg"
cp LICENSE README.md SECURITY.md docs/AMEACAS.md "$ROOT/usr/share/doc/$NAME/"
# Os textos das licenças do que foi compilado, que o Flutter junta no bundle
gunzip -c "$BUNDLE/data/flutter_assets/NOTICES.Z" > "$ROOT/usr/share/doc/$NAME/NOTICES"
