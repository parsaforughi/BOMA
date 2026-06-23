#!/usr/bin/env bash
# Build and install Boma on the Android emulator (reinstall + launch).
# Usage: ./install_emulator.sh [device_id]
# Auto-picks the first running emulator when device_id is omitted.

set -euo pipefail
cd "$(dirname "$0")"

export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$(pwd)/.gradle-user-home}"
export PATH="$JAVA_HOME/bin:${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools:$PATH"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

resolve_device() {
  if [ -n "${1:-}" ]; then
    echo "$1"
    return
  fi
  adb devices | awk '/^emulator-[0-9]+[[:space:]]+device$/{print $1; exit}'
}

DEVICE="$(resolve_device "${1:-}")"
if [ -z "$DEVICE" ]; then
  echo "No Android emulator found. Start one in Android Studio, then run again."
  exit 1
fi

APK="build/app/outputs/flutter-apk/app-debug.apk"
PKG="com.boma.app"

echo "Building debug APK..."
flutter build apk --debug

echo "Installing on $DEVICE..."
adb -s "$DEVICE" install -r "$APK"

echo "Launching $PKG..."
adb -s "$DEVICE" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true

echo "Done — latest build is on $DEVICE."
