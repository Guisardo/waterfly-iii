#!/bin/bash
set -e

SDK_ROOT="$HOME/Library/Android/sdk"

echo "Installing Android 10 (API 29) system image..."
yes | $SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "system-images;android-29;google_apis;x86_64" 2>/dev/null || \
yes | $SDK_ROOT/tools/bin/sdkmanager "system-images;android-29;google_apis;x86_64" 2>/dev/null

echo "Creating emulator..."
echo "no" | $SDK_ROOT/cmdline-tools/latest/bin/avdmanager create avd \
  -n Android10_API29 \
  -k "system-images;android-29;google_apis;x86_64" \
  -d pixel 2>/dev/null || \
echo "no" | $SDK_ROOT/tools/bin/avdmanager create avd \
  -n Android10_API29 \
  -k "system-images;android-29;google_apis;x86_64" \
  -d pixel

echo "Starting emulator..."
$SDK_ROOT/emulator/emulator -avd Android10_API29 -no-snapshot-load &

echo "Done! Emulator starting..."
