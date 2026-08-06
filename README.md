# Doodh Khata Mobile

Offline-first Flutter MVP for the **Doodh Khata** milk delivery ledger (`doodh_khata_mobile`, org `com.doodhkhata`).

Suppliers manage customers, subscriptions, daily deliveries, bills, and payments. Customers get a read-mostly view of calendar, history, bills, and payments.

## Prerequisites

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ / Dart 3.5+).
2. This repo was scaffolded **without** `flutter create` (Flutter was not available on the authoring machine). Generate platform folders before the first run:

```bash
chmod +x scripts/bootstrap_platforms.sh
./scripts/bootstrap_platforms.sh
```

That runs:

```bash
flutter create . \
  --project-name doodh_khata_mobile \
  --org com.doodhkhata \
  --platforms=android,ios
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`applicationId` / bundle id become `com.doodhkhata.doodh_khata_mobile`.

## Architecture

Feature-first layout under `lib/`:

```
lib/
├── main.dart / bootstrap.dart
├── app/          # MaterialApp, go_router, shells, theme
├── core/         # API (Dio), SQLite, env, sync, formatters, secure storage
└── features/     # splash, auth, dashboard, customers, subscriptions,
                  # deliveries, calendar, billing, payments, notifications,
                  # profile, settings
```

Each feature follows `data / domain / presentation`.

### Offline-first + sync

- Writes go to **SQLite first** (`AppDatabase`), then enqueue into `sync_queue`.
- UI reads via DB queries / light polling streams.
- `SyncService` pushes the queue, pulls remote changes, uses a **single-flight** lock and exponential **backoff**.
- Sync statuses: `LOCAL_ONLY`, `PENDING`, `SYNCING`, `SYNCED`, `FAILED`, `CONFLICT`.
- Tokens live only in **flutter_secure_storage**. Logout clears tokens + local user tables.

Drift **table definitions** live in `lib/core/database/tables.dart` (source of truth for future full Drift codegen). Runtime CRUD uses `sqlite3` through `AppDatabase` so the project compiles before `build_runner` has been run.

### Auth

Splash restores session → login / supplier register → role-based home (supplier vs customer). Forgot-password is a placeholder (OTP marked as future).

## Environments (`--dart-define`)

| Define | Purpose | Default |
|--------|---------|---------|
| `APP_ENV` | `development` / `staging` / `production` | `development` |
| `API_BASE_URL` | Backend base URL | `http://10.0.2.2:3000/api/v1` |
| `ENABLE_API_LOGS` | Dio log interceptor | `true` |

### Host cheat sheet

| Runtime | API host |
|---------|----------|
| Android emulator | `http://10.0.2.2:3000/api/v1` (maps to host loopback) |
| iOS Simulator | `http://127.0.0.1:3000/api/v1` |
| Physical device | `http://<your-lan-ip>:3000/api/v1` (phone and computer on same Wi‑Fi) |

Example:

```bash
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 \
  --dart-define=ENABLE_API_LOGS=true
```

When the API is unreachable, login/register fall back to a **local-only** session so offline demos still work.

## Android / iOS

After bootstrap:

- Android: ensure `INTERNET` permission (Flutter template includes it). Material 3 theme is applied in Dart.
- iOS: App Transport Security may block cleartext HTTP — for LAN/dev, allow arbitrary loads in `Info.plist` or use HTTPS.

### Signing, APK, AAB

Debug APK:

```bash
flutter build apk --debug
```

Release APK / Play App Bundle (configure signing first):

1. Create a keystore (keep it out of git — see `.gitignore`).
2. Add `android/key.properties` (not committed):

```properties
storePassword=...
keyPassword=...
keyAlias=doodhkhata
storeFile=/absolute/path/to/upload-keystore.jks
```

3. Wire `android/app/build.gradle` signingConfigs (Flutter template docs).
4. Build:

```bash
flutter build apk --release
flutter build appbundle --release
```

## Testing

```bash
flutter test
```

Covered today:

- Login validation
- Delivery amount calculation
- Local delivery creation + sync enqueue
- Sync queue persistence / backoff marker
- Bill preview aggregation
- Supplier dashboard widget render

## PDF bills

`BillPdfService` builds an A4 PDF (`pdf` + `printing`) and shares via `Printing.sharePdf` / `share_plus`.

## Theme

Outdoor-friendly dairy palette (teal / leaf green / cream). Material 3 — not purple gradient defaults.

## Known limitations

- Flutter SDK was **not** installed when this tree was authored; run `scripts/bootstrap_platforms.sh` first.
- Full Drift `@DriftDatabase` codegen is prepared via table classes; runtime uses `AppDatabase` SQL helpers.
- Pull-sync mapping awaits a finalized backend contract (`GET /sync/pull`).
- OTP forgot-password is intentionally stubbed.
- Notifications screen is a placeholder until FCM topics are wired.
# Dudh_wala_Mobile
# Dudh_wala_Mobile
