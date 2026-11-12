# Security

Psito Chirp is a messenger whose whole point is privacy, so security reports are the most welcome kind of issue.

## Reporting a vulnerability

Please **do not open a public issue** for a vulnerability. Use GitHub's private reporting instead: on the repository page, open **Security → Report a vulnerability**. Only the maintainers see it.

Include what you can:

- the version (the profile screen shows the core version and the protocol number);
- the system (Linux, Windows, macOS, Android or iOS);
- what an attacker needs (being on the same network, being a contact, holding the device) and what they get;
- steps to reproduce, or a test.

You get an answer within a week. Once a fix is out, the release notes credit you, unless you prefer otherwise.

## Supported versions

Only the latest release gets fixes. There is no automatic update that calls a server: update through the APT or DNF repository, the AUR, the installer or the APK on the releases page.

## What Chirp protects, and what it does not

The full threat model, with what is done today and what is not, is in [`docs/AMEACAS.md`](docs/AMEACAS.md) (in Portuguese). In short:

- **Protected**:
  - the content of messages and files, end to end, with the Signal protocol (`libsignal`): PQXDH, which is X25519 plus ML-KEM, and then the Double Ratchet;
  - sizes padded to fixed steps;
  - the local database encrypted with SQLCipher, with its key in the system keychain or derived from a passphrase with Argon2id;
  - no servers of ours, no accounts, no logs and no telemetry.
- **Not protected**:
  - a device that is compromised (malware, root);
  - hiding *that* you use Chirp from someone watching the local network;
  - your IP address from your contacts when the internet is on, or from a relay you configure;
  - what a contact does with what you send them.

## Scope

In scope: the Rust core (`core/`), the Flutter app (`lib/`), the platform code (`android/`, `ios/`, `linux/`, `macos/`, `windows/`), the protocol ([`docs/PROTOCOLO.md`](docs/PROTOCOLO.md)) and the packages we publish.

Out of scope: bugs in `libsignal`, `iroh`, SQLCipher or Flutter themselves (report those upstream; tell us too if Chirp is affected), and self-hosted relays run by third parties.
