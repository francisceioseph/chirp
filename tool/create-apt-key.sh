#!/bin/bash
# Cria a chave que assina o repositório APT e guarda a parte privada nos segredos do
# GitHub, como APT_SIGNING_KEY. Sem senha, porque quem assina é o CI. Rode uma vez só:
# outra chave obrigaria quem já instalou a adicioná-la de novo.
# Uso: tool/create-apt-key.sh
set -e

BACKUP="$HOME/psito-chirp-apt-key.asc"
[ ! -e "$BACKUP" ] || {
    echo "Já existe $BACKUP: a chave já foi criada." >&2
    exit 1
}

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
trap 'rm -rf "$GNUPGHOME"' EXIT

gpg --batch --quiet --passphrase '' --quick-generate-key \
    'Psito Chirp packages <francisceioseph@users.noreply.github.com>' \
    ed25519 sign never

(umask 077 && gpg --batch --armor --export-secret-keys > "$BACKUP")
gh secret set APT_SIGNING_KEY --repo francisceioseph/chirp < "$BACKUP"

echo "Chave criada e enviada ao GitHub."
echo "Guarde uma cópia de $BACKUP fora deste computador."
