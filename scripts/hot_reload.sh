#!/usr/bin/env bash
# Hot-reload BOMA on the Android emulator (debug session).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export PATH="${PATH}:${HOME}/Library/Android/sdk/platform-tools"
DEVICE="${FLUTTER_DEVICE:-emulator-5554}"

if ! command -v flutter >/dev/null 2>&1; then
  exit 0
fi

if ! adb devices 2>/dev/null | grep -qE "${DEVICE}[[:space:]]+device"; then
  exit 0
fi

# Debounce rapid successive edits (2s).
STAMP="${ROOT}/.cursor/.last_hot_reload"
now=$(date +%s)
if [[ -f "$STAMP" ]]; then
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  if (( now - last < 2 )); then
    exit 0
  fi
fi
echo "$now" > "$STAMP"

export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-${ROOT}/.gradle-user-home}"

PID_FILE="${ROOT}/.cursor/flutter_dev.pid"

_start_flutter_run() {
  nohup flutter run -d "$DEVICE" --no-pub >>"${ROOT}/.cursor/flutter_dev.log" 2>&1 &
  echo $! >"$PID_FILE"
  sleep 12
}

# Ensure a flutter run debug session exists (hot reload needs it).
if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE" 2>/dev/null || true)
  if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
  fi
fi

if [[ ! -f "$PID_FILE" ]]; then
  _start_flutter_run
fi

# Signal hot reload to the VM service (works with active `flutter run`).
if printf 'r' | timeout 25 flutter attach -d "$DEVICE" --debug 2>/dev/null; then
  exit 0
fi

# Attach failed — restart dev session and try once more.
_start_flutter_run
printf 'r' | timeout 25 flutter attach -d "$DEVICE" --debug 2>/dev/null || true
