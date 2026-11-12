# Psito Chirp

A private messenger with no servers in the middle: conversations go straight from one device to the other, over the local network, the internet or Bluetooth, encrypted end to end from the very first message. No accounts, no phone numbers, no logs and no telemetry. For Linux, Windows, macOS, Android and iOS.

> **Status: being rebuilt.** The old prototype (kept in the `prototipo-2026` tag) was not secure: see the diagnosis in [`docs/PLANO.md`](docs/PLANO.md). The new version has a Rust core (cryptography, networking and storage) under a Flutter interface. Right now there is the identity, the encrypted storage, adding contacts on the local network with a post-quantum Signal handshake, and one-to-one messaging: delivery and read receipts, typing, replies, edits, deletes for everyone, reactions, "nudges" and search, with an offline queue that survives restarts.

## The plan, in short

- **Encryption**: the Signal protocol's Double Ratchet with post-quantum key agreement (PQXDH), through `libsignal`.
- **Networks**: local network with no internet needed, the internet with NAT traversal and an optional self-hostable relay, and Bluetooth LE.
- **Adding a contact**: scan a QR code in person, open an invite link, or find each other nearby and compare a short code.
- **Storage**: an encrypted database, with the key in the system keychain.
- **Interface**: Material 3 with themes, in seven languages.

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
