#!/bin/bash
# Compila e monta o pacote .rpm para o Fedora, sem sudo. Leva o mesmo bundle do .deb.
# As dependências vão à mão, sem o AutoReq, porque o Flutter abre o EGL e o GLES na
# hora de desenhar e porque o rpm procuraria dentro do bundle por bibliotecas que já
# vêm nele.
# Uso: tool/build-rpm.sh [pasta de saída, padrão build/rpm] [--no-build]
set -e

cd "$(dirname "$0")/.."

OUT="$(realpath -m "${1:-build/rpm}")"
VERSION="$(sed -n 's/^version: \([^+]*\).*/\1/p' pubspec.yaml)"
NAME=psito-chirp

[ "$2" = "--no-build" ] || flutter build linux --release

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
tool/stage-package.sh "$WORK/stage"

cat > "$WORK/$NAME.spec" <<SPEC
%global debug_package %{nil}
%global __os_install_post %{nil}
%global _build_id_links none

Name: $NAME
Version: $VERSION
Release: 1
Summary: Private messenger with no servers in the middle
License: AGPL-3.0-only
URL: https://github.com/francisceioseph/chirp
AutoReqProv: no
Requires: glibc >= 2.38
Requires: gtk3
Requires: glib2 >= 2.80
Requires: libsecret
Requires: mesa-libEGL
Requires: mesa-libGLES
Recommends: mesa-dri-drivers

%description
Conversations go straight from one device to the other, over the local
network or the internet, encrypted end to end with the Signal protocol.
No accounts, no phone numbers, no logs and no telemetry.

%install
cp -a "$WORK/stage/." %{buildroot}/

%files
/usr/bin/$NAME
/usr/lib/$NAME
/usr/share/applications/org.psito.chirp.desktop
/usr/share/metainfo/org.psito.chirp.metainfo.xml
/usr/share/icons/hicolor/scalable/apps/org.psito.chirp.svg
/usr/share/doc/$NAME
SPEC

mkdir -p "$OUT"
rpmbuild -bb "$WORK/$NAME.spec" --target x86_64 \
    --define "_topdir $WORK/rpmbuild" \
    --define "_rpmdir $OUT" \
    --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" >/dev/null 2>&1
echo "$OUT/$NAME-$VERSION-1.x86_64.rpm"
