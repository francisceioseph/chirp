#!/bin/bash
# Grava a versão no app e no núcleo, para os dois andarem juntos (a tela mostra a do
# núcleo). Quem chama é o semantic-release, no CI.
# Uso: tool/set-version.sh <versão>
set -e

cd "$(dirname "$0")/.."

VERSION="${1:?uso: tool/set-version.sh <versão>}"
sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml
sed -i "0,/^version = .*/s//version = \"$VERSION\"/" core/chirp-core/Cargo.toml
sed -i "/^name = \"chirp_core\"$/{n;s/^version = .*/version = \"$VERSION\"/}" core/Cargo.lock
