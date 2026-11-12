#!/bin/bash
# Monta o repositório DNF em arquivos estáticos, a partir dos .rpm, assinando os pacotes
# e o índice com a chave que estiver no gpg. O CI publica o resultado no GitHub Pages.
# Uso: tool/build-dnf-repo.sh <pasta de saída> <URL pública> <arquivo.rpm>...
set -e

OUT="$1"
URL="$2"
shift 2 || true
[ -n "$OUT" ] && [ -n "$URL" ] && [ $# -gt 0 ] || {
    echo "Uso: $0 <pasta de saída> <URL pública> <arquivo.rpm>..." >&2
    exit 1
}

mkdir -p "$OUT/rpm"
cp "$@" "$OUT/rpm/"

KEY="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr/ { print $10; exit }')"
rpmsign --addsign --define "_gpg_name $KEY" --define "__gpg $(command -v gpg)" "$OUT"/rpm/*.rpm >/dev/null

createrepo_c --quiet "$OUT/rpm"
gpg --batch --yes --armor --detach-sign -o "$OUT/rpm/repodata/repomd.xml.asc" "$OUT/rpm/repodata/repomd.xml"
gpg --batch --yes --armor --export > "$OUT/psito-chirp.asc"

cat > "$OUT/psito-chirp.repo" <<REPO
[psito-chirp]
name=Psito Chirp
baseurl=$URL/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$URL/psito-chirp.asc
REPO
