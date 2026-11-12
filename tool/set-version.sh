#!/bin/bash
# Grava a versão no app e no núcleo, para os dois andarem juntos (a tela mostra a do
# núcleo). O número depois do + é o versionCode do Android, que só pode subir:
# 1.2.3 vira 1002003. Quem chama é o semantic-release, no CI.
# Uso: tool/set-version.sh <versão>
set -e

cd "$(dirname "$0")/.."

VERSION="${1:?uso: tool/set-version.sh <versão>}"
IFS=. read -r MAJOR MINOR PATCH <<< "${VERSION%%-*}"
CODE=$((MAJOR * 1000000 + MINOR * 1000 + PATCH))
sed -i "s/^version: .*/version: $VERSION+$CODE/" pubspec.yaml
sed -i "0,/^version = .*/s//version = \"$VERSION\"/" core/chirp-core/Cargo.toml
sed -i "/^name = \"chirp_core\"$/{n;s/^version = .*/version = \"$VERSION\"/}" core/Cargo.lock
