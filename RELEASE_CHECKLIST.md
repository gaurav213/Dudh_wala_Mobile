# Store release checklist — Doodh Wala (`doodh_khata_mobile`)

Framework: **Flutter 3.24+** · Package: `com.doodhkhata.doodh_khata_mobile` (Android) / `com.doodhkhata.doodhKhataMobile` (iOS)

Copy `dart_defines/production.json.example` → `dart_defines/production.json` and set your real HTTPS API URL (file is git-ignored via `.env` patterns; keep secrets out of git).

---

## Android Release

- [ ] Production package name: `com.doodhkhata.doodh_khata_mobile`
- [ ] Version in `pubspec.yaml` (`x.y.z+build`) — bump **build** (`+N`) every Play upload
- [ ] `APP_ENV=production` + HTTPS `API_BASE_URL`
- [ ] Upload keystore created (not debug)
- [ ] `android/key.properties` present (from `key.properties.example`)
- [ ] `STORE_RELEASE=1 flutter build appbundle --release --dart-define-from-file=dart_defines/production.json`
- [ ] AAB builds successfully
- [ ] Permissions audited (INTERNET, location, camera, notifications)
- [ ] Cleartext disabled in release (`network_security_config`)
- [ ] Icons / adaptive icon / splash verified
- [ ] Account deletion path tested (Settings → Delete account)
- [ ] No local-only offline login in production
- [ ] No secrets in the binary
- [ ] Play Console: Data Safety, privacy policy URL, content rating
- [ ] Screenshots + feature graphic ready

## iOS Release

- [ ] Bundle ID: `com.doodhkhata.doodhKhataMobile` (registered in Apple Developer)
- [ ] Version / build from `pubspec.yaml`
- [ ] Same production dart-defines as Android
- [ ] Apple Developer Team + distribution signing in Xcode
- [ ] Archive → Validate → Distribute to App Store Connect
- [ ] Info.plist usage strings (camera, photos, location when-in-use)
- [ ] `PrivacyInfo.xcprivacy` in app bundle
- [ ] App icons + launch screen
- [ ] Account deletion tested
- [ ] App Privacy questionnaire + privacy policy URL
- [ ] Export compliance / age rating completed
- [ ] Demo account for App Review (if login required)

## Final QA

- [ ] English / Hindi / Marathi
- [ ] Login / register / logout
- [ ] Core farm + customer + delivery flows
- [ ] Offline / timeout messages (no crash)
- [ ] Notifications (local poll) + deep route tap
- [ ] Delete account
- [ ] Release build smoke test (not only debug)

## Manual blockers (cannot be faked in repo)

- [ ] Production API hostname (HTTPS)
- [ ] Google Play Console account + listing
- [ ] Apple Developer Program + App Store Connect
- [ ] Privacy policy URL + support URL
- [ ] Upload keystore passwords (kept offline)
- [ ] Optional: FCM/APNs if you want killed-app push later
