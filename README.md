# Psito Chirp

A private messenger with no servers in the middle: conversations go straight from one device to the other, over the local network, the internet or Bluetooth, encrypted end to end from the very first message. No accounts, no phone numbers, no logs and no telemetry. For Linux, Windows, macOS, Android and iOS.

> **Status: being rebuilt.** The old prototype (kept in the `prototipo-2026` tag) was not secure: see the diagnosis in [`docs/PLANO.md`](docs/PLANO.md). The new version has a Rust core (cryptography, networking and storage) under a Flutter interface. Right now there is the foundation, the identity and the encrypted storage; messaging arrives in the next phases.

## The plan, in short

- **Encryption**: the Signal protocol's Double Ratchet with post-quantum key agreement (PQXDH), through `libsignal`.
- **Networks**: local network with no internet needed, the internet with NAT traversal and an optional self-hostable relay, and Bluetooth LE.
- **Adding a contact**: scan a QR code in person, open an invite link, or find each other nearby and compare a short code.
- **Storage**: an encrypted database, with the key in the system keychain.
- **Interface**: Material 3 with themes, in seven languages.

## Building

You need Flutter 3.47.4 and a stable Rust toolchain. The Rust core is built automatically by `flutter build`.

```bash
flutter run -d linux
```

On Linux you also need `libgtk-3-dev`, `libsecret-1-dev`, `ninja-build`, `cmake`, `clang` and `pkg-config`.

## License

GPL-3.0. See [LICENSE](LICENSE).
