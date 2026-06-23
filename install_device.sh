#!/usr/bin/env bash
# Build and install Boma on connected Android device(s). Run after code changes.
# Usage: ./install_device.sh           → install on ALL connected Android devices
#        ./install_device.sh <device_id>  → install on one device (e.g. R92W6034HFR or emulator-5554)

set -e
cd "$(dirname "$0")"

echo "Building debug APK..."
flutter pub get
flutter build apk --debug

install_one() {
  echo "Installing on $1..."
  flutter install -d "$1" --debug
}

if [ -n "$1" ]; then
  install_one "$1"
else
  # Get Android device IDs (second column in "flutter devices" output)
  ANDROID_IDS=$(flutter devices 2>/dev/null | grep -E 'android-arm|android-x86' | awk -F'•' '{gsub(/^ +| +$/,"",$2); if($2!="") print $2}')
  if [ -z "$ANDROID_IDS" ]; then
    echo "No Android device found. Connect a device or run: ./install_device.sh <device_id>"
    exit 1
  fi
  for id in $ANDROID_IDS; do
    install_one "$id" || true
  done
fi

echo "Done. App is updated on your device(s)."
