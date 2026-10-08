#!/usr/bin/env bash
# One-time setup: generates the Android scaffolding that matches YOUR installed
# Flutter version, then wires in the INTERNET permission needed for Gemini.
# Run from inside the skillforge_ai folder:  bash setup.sh
set -euo pipefail

command -v flutter >/dev/null || { echo "Flutter SDK not found on PATH."; exit 1; }

# Creates android/, .metadata, etc. Existing lib/, test/ and pubspec.yaml stay.
flutter create --platforms=android --project-name skillforge_ai --org com.skillforge .

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  # flutter create only adds INTERNET to the debug/profile manifests; release needs it too.
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi
sed -i 's#android:label="[^"]*"#android:label="SkillForge AI"#' "$MANIFEST"

flutter pub get
echo
echo "Next:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter build apk --release                                  # works offline (rule-based engine)"
echo "  flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY   # with Gemini enabled"
echo
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
