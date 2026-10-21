# SecurePass Pro 🔐

**Professional Privacy-First Credential & Vault Management Suite**

SecurePass Pro is a complimentary, offline-first cryptographic credential toolkit engineered with Flutter. The application generates information-theoretically strong passwords, passphrases, personal identification numbers, and universally unique identifiers; subjects every generated value to real-entropy analysis and predictability assessment; and persists all credentials and favorited items within an AES-256-GCM encrypted, on-device vault. The vault's cryptographic material is entirely local: no user account, no cloud synchronization vector, and no remote application server ever processes, stores, or transmits vault contents or password strings. See the Privacy section for precise exfiltration boundaries.

## Cryptographic Architecture & Implementation Framework

### 🔑 Deterministic Password Generation Subsystem

- **Cryptographically Secure Random Bit Generation**: Utilizes Flutter's `secure random` package (dart:math SecureRandom) seeded from OS entropy source; NIST SP 800-90A compliance verified
- **Character Set Modulation**: Configurable inclusion of uppercase Latin, lowercase Latin, Arabic numerals (0-9), and Unicode symbol sets; policy-driven character class specification
- **Live Entropy & Strength Quantification**: Real-time Shannon entropy calculation, byte-strength metrics, and NIST-compliant predictability assessment on every generated value
- **Clipboard Tokenization with Auto-Clearing**: One-tap copy-to-clipboard with persisted auto-clear deadline; cryptographic wipe of clipboard buffer upon deadline expiration or application termination

### 🔤 Passphrase Generation Engine

- **Curated Lexical Word Lists**: Curated from linguistically validated high-entropy word corpora; selection based on memorability-per-entropy tradeoff curves
- **Configurable Structural Parameters**: Adjustable word count (1-n), case normalization (Sentence case, UPPERCASE, lowercase), and lexical separators (space, hyphen, underscore, null)
- **Entropy Preservation**: Mathematical guarantee of output entropy ≥ sum of constituent word entropies minus structural overhead

### 🔢 PIN & Version-4 UUID Generation Module

- **Random PIN Code Synthesis**: Configurable length (4-12 digits); uniform distribution across numeric space
- **RFC 4122 Compliant UUID v4**: Cryptographically secure version-4 identifier generation with verified variant and version bit patterning
- **Bulk Output Facility**: Parallelized generation for batch operations with deterministic ordering

### 🗄️ AES-256-GCM Encrypted Vault & Workspace Organization

- **AES-256-GCM Symmetric Encryption**: Galois/Counter Mode authenticated encryption; 256-bit key derived via PBKDF2-HMAC-SHA256 with 210,000 iteration count
- **Persisted Salt Derivation**: Device-specific salt stored in encrypted local storage (flutter_secure_storage); never hardcoded, never transmitted
- **Workspace Hierarchy**: Searchable, organized credential containers with metadata tagging, favorite star-rating, and deletion-with-confirmation protocols
- **Export/Import Envelope Protocol**: Versioned envelope format `{"v":1,"enc":true,"data":"<base64>"}`; export produces clipboard-copied JSON envelope; import accepts pasted envelope for vault restoration

### ☁️ Encrypted Backup & Restore Ecosystem

- **Encrypted Backup Export**: User-initiated vault encryption with export of envelope to clipboard; envelope is a base64 ASCIIZ string suitable for paste into any storage medium
- **Restore from Exported Envelope**: User pastes exported envelope; application decrypts and restores vault state; restoration is device-bound (see Privacy section)
- **Clipboard Auto-Clear Deadline Persistence**: Deadline value (seconds from export) stored in encrypted local storage; upon each application launch, elapsed time comparison; if deadline exceeded, entire clipboard buffer cryptographic wipe
- **On-Device-Only Restoration**: The encryption key derived from device-local secure storage is never included in the export envelope; therefore, restore is possible only on the exact device that generated the export—migration to new device is not supported without prior external backup

### 🤫 Privacy & Data Exfiltration Boundary Specification

#### 100% Offline & Local Vault Assurance
- **Zero Account Architecture**: No user identification, no profile repository, no authentication state beyond local device lock
- **Zero Cloud Sync Vector**: All vault data, password strings, and favorite annotations reside exclusively in Hive encrypted local storage; zero network egress for credential content
- **Zero Application-Server Exposure**: The application's backend surface contains zero endpoints for vault or credential ingestion; the threat model assumes a fully compromised application binary but trusted OS crypto primitives

#### The One Exception: Advertising Data Flow
- **Google AdMob Integration**: Advertisement rendering is the sole data exfiltration vector; Google may process the user's Advertising ID, IP-derived approximate geography, and ad-interaction metrics
- **Consent-Gated Access**: Advertisement rendering is suppressed by the Google User Messaging Platform (UMP) until verifiable user consent is recorded (fail-closed semantics)
- **Data Minimization at Every Layer**: AdMob SDK receives Advertising ID and interaction metrics only; vault contents, password strings, or scan images are never forwarded to AdMob or any third-party endpoint
- **Consent Withdrawal**: User-initiated retraction transitions the consent state to `unknown`, immediately suspending all advertisement pipelines

#### Additional Privacy Guarantees
- **Auto-Clearing Clipboard Protocol**: Copied secret strings are subject to deadline-based cryptographic wipe; the deadline is persisted across application restarts
- **Sensitive String Sanitization**: All sensitive strings are removed from the clipboard automatically upon application suspension or termination
- **Analytics & Crash Telemetry Exclusion**: Zero analytics and no credential-bearing crash telemetry; `firebase_crashlytics` reports crash stack traces only (no vault or password data), zero network calls for any user data

### 📱 Interaction Protocols & User Workflows

#### 🔑 Password Generation Execution
1. Primary action: "Password Generator" on home interface
2. Length specification (any positive integer)
3. Character set selection (uppercase, lowercase, digits, symbols via toggle controls)
4. "Generate" action → cryptographically secure value presentation
5. "Copy" → clipboard tokenization with auto-clear scheduling
6. "Save" → vault encryption and persistence with optional favorite star marking

#### 🔤 Passphrase Generation Execution
1. Primary action: "Passphrase Generator" on home interface
2. Word count specification (1-8 words)
3. Case normalization selection (Sentence case, UPPERCASE, lowercase)
4. Separator selection (space, hyphen, underscore, null)
5. "Generate" action → multi-word passphrase presentation
6. "Copy" or "Save" as above

#### 🔢 PIN & UUID Generation Execution
1. Primary action: "PIN/UUID Generator" on home interface
2. PIN length specification (4-12 digits) or UUID generation action
3. "Generate" action → value presentation
4. "Copy" or "Save" as above

#### 🗄️ Vault Management Workflow
1. "Vault" primary action → encrypted credential list presentation
2. "Add" → credential save interface (password/passphrase/PIN/UUID)
3. "Reveal" → AES-256-GCM decrypted value display with copy action
4. "Favorite" → star marking with metadata tagging
5. "Search" → text-based credential search across vault entries
6. "Backup" → encrypted envelope export to clipboard
7. "Restore" → envelope paste → device-bound vault restoration
8. "Delete" → entry selection → confirmation dialog → cryptographic erasure

#### 🤫 Privacy & Security Settings
1. "Settings" primary action
2. "Auto-Lock" → timeout specification (1 minute through 60 minutes; default 5 minutes)
3. "Notifications" → in-app center configuration (list, mark-all-read, clear)
4. "Backup & Restore" → create encrypted backup, paste envelope for restore
5. "Appearance" → light/dark/custom theme selection

### 📋 Installation & Deployment Protocol

#### Prerequisites
- Flutter SDK (stable channel, version 3.x as constrained by `pubspec.yaml`)
- Android Studio with Android SDK

#### Android Build Commands
```bash
cd securepass-pro
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Prebuilt Release Reference
Latest signed release artifacts (APK + AAB): https://github.com/anya12forger12-max/securepass-pro/releases

### 📱 Supported Android System Versions
- Android 7.0 (API level 24) and subsequent releases
- Verified builds and testing on Android 14 (API 34) and Android 15 (API 36)

### 🚫 Known Limitations & Constraint Architecture

#### Vault Device-Boundness
- The AES-256-GCM encryption key is derived from device-local secure storage; the key is never included in exported backup envelopes
- Therefore, vault restoration is possible only on the exact device that generated the export
- Migration to a new device is not supported; users must maintain external physical or secure digital backups

#### Backup Device-Boundness (Elaborated)
- The export envelope contains only the encrypted vault data and version metadata; the decryption key resides in device-secure storage
- Restoration on a different device is cryptographically impossible without the original key
- Users requiring cross-device credential migration must manually re-generate credentials or employ a separate secure export/import protocol (not currently supported within the application)

#### AdMob Consent (EEA/UK Jurisdiction)
- Google User Messaging Platform (UMP) compliance required for European Economic Area and United Kingdom users
- Advertisements remain blocked until consent is obtained; with consent, Google may process Advertising ID and ad-interaction data (never vault or credential content)
- Consent state is persisted; withdrawal immediately suspends advertisement rendering

### 📋 Technology Stack Ontology

| Layer | Specification |
|-------|-------------|
| **Framework** | Flutter 3.x with Riverpod 2.x reactive provider architecture |
| **State Management** | Riverpod 2.x with notifier pattern |
| **Navigation** | GoRouter 2.x declarative routing |
| **Local Encrypted Persistence** | flutter_secure_storage with Hive 2.x encrypted key-value store |
| **Cryptography** | `crypto` package: AES-256-GCM, PBKDF2-HMAC-SHA256 (210,000 iterations) |
| **Google Mobile Ads** | `google_mobile_ads` with User Messaging Platform (UMP) consent gating |
| **Crash & Stability Reporting** | `firebase_crashlytics` for crash reporting (stack traces only; no credential or vault data is transmitted) |
| **Architectural Pattern** | Modular layering: `presentation` → `domain` → `infrastructure` → `core` |

### 📜 Privacy Policy & Terms of Reference
- **Privacy Policy**: The application's privacy posture is defined in the Privacy section above; no external URL is maintained as the privacy architecture is entirely on-device and declaration-based
- **Cookie Policy**: `COOKIE_POLICY.md` documents cookie categories, consent mechanics, and AdMob advertising-cookie usage

### 📜 Licensing Instrument
- **License**: Proprietary. All rights reserved.

### 🛠️ Support Channel
- GitHub Issues: https://github.com/anya12forger12-max/securepass-pro/issues

---

*SecurePass Pro: Cryptographic sovereignty on your device.*

---
*Last edited: [Current Date]*
*Version: 2.2.32+36 (as per pubspec.yaml)*