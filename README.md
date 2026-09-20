# SecurePass Pro 🔐

**Professional Privacy-First Password & Credential Generator**

SecurePass Pro is a free, offline-first credential toolkit built with Flutter. It generates strong, cryptographically random passwords, passphrases, PINs, and UUIDs; grades every result with real entropy and strength analysis; and keeps your saved credentials and favorites locked in an **encrypted, on-device vault** — no account, no cloud, no tracking.

## Features

### 🔑 Password Generator
- Generate cryptographically random passwords of any length
- Control character sets (uppercase, lowercase, digits, symbols)
- Live strength & entropy analysis on every generated value
- One-tap copy to tokenized clipboard

### 🔤 Passphrase Generator
- Memorable multi-word passphrases from curated word lists
- Adjustable word count, case, and separators
- High entropy with an interface your brain can remember

### 🔢 PIN & UUID Generators
- Random PIN codes and numeric sequences
- Version-4-style UUIDs for IDs, keys, and references
- Bulk output for batch operations

### 🧪 Built-in Analysis
- Entropy, bit-strength, and pattern detection for any string
- Common-password and predictability checks (never score weak values as Strong)
- Policy templates so generated passwords meet your own rules

### 🗄️ Secure Vault & Workspaces
- Save credentials and favorites in an encrypted on-device vault
- Organized, searchable workspaces for credentials
- **AES-256-GCM encryption** with **PBKDF2-HMAC-SHA256 (210,000 iterations)** key derivation — a persisted salt on every device, not a hardcoded one

### ☁️ Encrypted Backups
- Export and restore your vault with real authenticated encryption (envelope format `{"v":1,"enc":true,"data":"<base64>"}`)
- Nothing on your device is ever decrypted or readable by anyone but you

### 🤫 Privacy
- **100% offline & local** — no accounts, no telemetry, no cloud sync
- Auto-clearing clipboard for copied secrets
- Optional on-device auto-lock and security settings
- Ads are fully blocked until you give consent (Google UMP, fail-closed)

### 📱 Extras
- 🎨 Theme Studio — light/dark/custom themes
- 💡 Onboarding, in-app Help, and diagnostics screen
- 🔄 Crash-resistant, durable architecture (Riverpod + GoRouter)

## How to Use

1. **Generate** a password: Home → **Password Generator** → set length & character sets → tap generate.
2. **Grade anything**: type or paste a string anywhere analysis is shown; watch the entropy meter and suggestions.
3. **Save it**: tap save to add the value to your secure vault / favorites.
4. **Back up**: Settings → Backup → create an encrypted backup file and keep it somewhere safe; restore it on a new device with your record.
5. **Stay private**: the app never touches a server for your data. Your vault lives only on your device.

## Use Cases

- Creating unique, high-entropy passwords for every online account
- Memorizing a strong **passphrase** instead of a fragile password
- Generating PINs and UUIDs for account recovery, dev/test fixtures, and unique identifiers
- Keeping sensitive credentials organized offline, on one device

## Installation

### Prerequisites
- Flutter 3.x (see `pubspec.yaml` for exact SDK constraints)
- Android Studio / Android SDK for Android builds

### Android (APK)
```bash
cd securepass-pro
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android (App Bundle)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Latest signed prebuilt release (APK + AAB): see the [Releases](https://github.com/anya12forger12-max/securepass-pro/releases) page.

## Technology Stack

- **Flutter / Dart** with **Riverpod** (state) and **GoRouter** (navigation)
- **flutter_secure_storage** for encrypted local persistence
- **cryptography / crypto** for AES-256-GCM and PBKDF2-HMAC-SHA256
- **google_mobile_ads (UMP)** consent-gated, privacy-compliant ads
- Modular layering: `presentation` → `domain` → `infrastructure` → `core`

## Security Notes

- Passwords are generated with a secure random source; UI never logs or leaks values.
- The vault, favorites, and history are encrypted on-device.
- Sensitive strings are removed from the clipboard automatically.
- No analytics, no crash telemetry for credentials, no network calls for your data.

## License

Proprietary. All rights reserved.

## Support

Report issues via the [GitHub Issues](https://github.com/anya12forger12-max/securepass-pro/issues) tab.