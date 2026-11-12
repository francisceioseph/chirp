#!/bin/bash
# Cria a chave que assina o APK e guarda nos segredos do GitHub (ANDROID_KEYSTORE, em
# base64, e ANDROID_KEY_PASSWORD). Rode uma vez só: o Android só instala uma
# atualização assinada com a mesma chave, e quem perder esta perde as atualizações.
# Uso: tool/create-android-key.sh
set -e

BACKUP="$HOME/psito-chirp-android.jks"
[ ! -e "$BACKUP" ] || {
    echo "Já existe $BACKUP: a chave já foi criada." >&2
    exit 1
}

PASSWORD="$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)"
(umask 077 && keytool -genkeypair -keystore "$BACKUP" -storetype PKCS12 \
    -alias chirp -keyalg RSA -keysize 4096 -validity 36500 \
    -storepass "$PASSWORD" -dname 'CN=Psito Chirp' >/dev/null 2>&1)
(umask 077 && printf '%s\n' "$PASSWORD" > "$BACKUP.password")

base64 -w0 "$BACKUP" | gh secret set ANDROID_KEYSTORE --repo francisceioseph/chirp
gh secret set ANDROID_KEY_PASSWORD --repo francisceioseph/chirp <<< "$PASSWORD"

echo "Chave criada e enviada ao GitHub."
echo "Guarde uma cópia de $BACKUP e de $BACKUP.password fora deste computador."
