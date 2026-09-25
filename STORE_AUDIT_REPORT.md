# Store deployment audit — Doodh Wala mobile

Date: 2026-09-06  
App: `doodh-khata-mobile` (Flutter)

## A. Project summary

| Item | Value |
|------|--------|
| Framework | Flutter (Dart 3.5+) |
| Android | `com.doodhkhata.doodh_khata_mobile`, label **Doodh Wala**, version from `pubspec` `1.0.0+1` |
| iOS | `com.doodhkhata.doodhKhataMobile`, display name **Doodh Wala** |
| Backend | NestJS (`doodh-khata-backend`) |
| Build | Gradle (Android) / Xcode (iOS) via Flutter |

## B. Overall status

```text
Android: NOT READY — BLOCKED (manual: signing + production HTTPS API + Play Console)
iOS:     NOT READY — BLOCKED (manual: Apple Team signing + production HTTPS API + App Store Connect)
```

Code/config blockers that were in the repo have been fixed; **external credentials and legal URLs remain**.

## C. Critical blockers (manual)

1. **Production HTTPS API URL** — no canonical prod host in repo. Copy `dart_defines/production.json.example` → `production.json`.
2. **Android upload keystore** + `android/key.properties` (use `key.properties.example`).
3. **Apple Developer Team** + distribution provisioning / Xcode signing.
4. **Privacy policy URL** + support URL for both stores.
5. **Google Play Console** + **App Store Connect** listings, Data Safety / App Privacy, screenshots.
6. **Forgot-password OTP** still stubbed (link hidden in non-dev builds).

## D. Fixed in this audit

1. `INTERNET` + `ACCESS_NETWORK_STATE` on **main** AndroidManifest (release networking).
2. Release cleartext blocked via `network_security_config.xml`.
3. Backup disabled + data extraction rules excluding secure storage / DB.
4. Adaptive launcher icons (`mipmap-anydpi-v26`).
5. Offline local-only login/register **gated to development only**.
6. Production bootstrap asserts HTTPS `API_BASE_URL` when `APP_ENV=production`.
7. Production ignores saved LAN API override.
8. `DELETE /auth/account` + Settings **Delete account** UI (EN/HI/MR).
9. Forgot-password entry hidden outside development.
10. Removed unused `NSLocationAlwaysAndWhenInUseUsageDescription`.
11. `CFBundleName` → Doodh Wala; app `PrivacyInfo.xcprivacy` wired into Xcode.
12. `STORE_RELEASE=1` fails the Gradle release if keystore missing.
13. `android/key.properties.example`, `dart_defines/production.json.example`, `RELEASE_CHECKLIST.md`.
14. Verified `flutter build appbundle --release` succeeds (debug-signed without keystore).

## E. Manual actions required

See `RELEASE_CHECKLIST.md`.

## F. Build commands

```bash
# Android Play AAB (after key.properties + production.json)
STORE_RELEASE=1 flutter build appbundle --release \
  --dart-define-from-file=dart_defines/production.json

# iOS IPA (after Apple signing configured)
flutter build ipa --release \
  --dart-define-from-file=dart_defines/production.json
```

## G. Verdict

**NOT READY — 5+ BLOCKERS REMAIN** (all external / account / legal / signing).  
Source is substantially closer to store submission; do not upload until section C is cleared.
