# Psito Chirp

A private messenger with no servers in the middle: conversations go straight from one device to the other, over the local network or the internet, encrypted end to end from the very first message. No accounts, no phone numbers, no logs and no telemetry. For Linux, Windows, macOS, Android and iOS.

> **Status: heading to 1.0.** A Rust core (cryptography, networking and storage) under a Flutter interface. The old prototype, kept in the `prototipo-2026` tag, was not secure: see the diagnosis in [`docs/PLANO.md`](docs/PLANO.md).

## What it does today

- One-to-one conversations with the Signal protocol (`libsignal`): PQXDH (X25519 plus ML-KEM) to start, then the Double Ratchet. Sizes are padded to fixed steps.
- The local network with no internet at all, and the internet when you turn it on, with an optional relay you can host yourself. No server is a default.
- Adding a contact by QR code or by an invite link that works once, with a safety code to compare in person.
- Delivery and read receipts, typing, replies, edits, deletes for everyone, reactions, nudges and search, with an outbox that survives restarts.
- Photos (without EXIF) and files, in encrypted 60 KiB pieces.
- Notifications that can hide the name and the text, the tray and start at login on the desktop, and a foreground service on Android to keep receiving with the app closed.
- An encrypted database (SQLCipher), with its key in the system keychain or derived from a passphrase.
- Material 3 themes, in seven languages: English, Portuguese, Spanish, French, German, Russian and Chinese.

## What comes next

After 1.0, following [`docs/PLANO.md`](docs/PLANO.md): a mailbox for contacts who are offline, Bluetooth LE, groups, voice and video calls, several devices per person with encrypted backup, and then Tor and an external audit.

## Install

Installers for Windows, Android and macOS (a test build), and the APT and DNF repositories for Debian, Ubuntu and Fedora, are on the [project page](https://francisceioseph.github.io/chirp/). The files are also on the [releases page](https://github.com/francisceioseph/chirp/releases), with their SHA-256 in `SHA256SUMS`.

## Security

What Chirp protects, and what it does not, is in the threat model, [`docs/AMEACAS.md`](docs/AMEACAS.md) (in Portuguese). To report a vulnerability privately, see [`SECURITY.md`](SECURITY.md).

## Building

You need Flutter 3.47.4 and a stable Rust toolchain. The Rust core is built automatically by `flutter build`.

```bash
flutter run -d linux
```

Building the core needs `protoc` (`protobuf-compiler`). On Linux you also need `libgtk-3-dev`, `libsecret-1-dev`, `ninja-build`, `cmake`, `clang` and `pkg-config`.

## License

GPL-3.0. See [LICENSE](LICENSE). The app links [libsignal](https://github.com/signalapp/libsignal), which is AGPL-3.0, so the binaries follow the AGPL-3.0 as a whole.
