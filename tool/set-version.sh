#!/bin/bash
# Grava a versão no app, no núcleo e na caixa postal, para os dois andarem juntos (a tela mostra a do
# núcleo). O número depois do + é o versionCode do Android, que só pode subir:
# 1.2.3 vira 1002003. Quem chama é o semantic-release, no CI.
# Uso: tool/set-version.sh <versão>
set -e

cd "$(dirname "$0")/.."

VERSION="${1:?uso: tool/set-version.sh <versão>}"
IFS=. read -r MAJOR MINOR PATCH <<< "${VERSION%%-*}"
CODE=$((MAJOR * 1000000 + MINOR * 1000 + PATCH))
sed -i "s/^version: .*/version: $VERSION+$CODE/" pubspec.yaml
for crate in chirp-core chirp-mailbox; do
  sed -i "0,/^version = .*/s//version = \"$VERSION\"/" "core/$crate/Cargo.toml"
done
for name in chirp_core chirp_mailbox; do
  sed -i "/^name = \"$name\"$/{n;s/^version = .*/version = \"$VERSION\"/}" core/Cargo.lock
done
