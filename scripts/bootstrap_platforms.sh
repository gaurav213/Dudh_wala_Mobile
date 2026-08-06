#!/usr/bin/env bash
# Bootstrap Android/iOS (and other) platform folders after installing Flutter.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Install Flutter, then re-run this script."
  echo "https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "→ flutter create (platforms only, preserve existing lib/)"
flutter create . \
  --project-name doodh_khata_mobile \
  --org com.doodhkhata \
  --platforms=android,ios

echo "→ flutter pub get"
flutter pub get

echo "→ build_runner (freezed / json_serializable / drift codegen)"
dart run build_runner build --delete-conflicting-outputs || true

echo ""
echo "Done. Next:"
echo "  flutter run --dart-define=APP_ENV=development \\"
echo "    --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 \\"
echo "    --dart-define=ENABLE_API_LOGS=true"
echo ""
echo "iOS Simulator API host: http://127.0.0.1:3000/api/v1"
echo "Physical device: use your machine LAN IP instead of 10.0.2.2"
