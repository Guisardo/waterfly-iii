#!/bin/bash

###############################################################################
# Connectivity Change Test Script
# Tests online/offline detection by toggling Android emulator connectivity
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Set ADB path
ADB="${HOME}/Library/Android/sdk/platform-tools/adb"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if device is connected
if ! $ADB devices | grep -q "device$"; then
    log_warn "No Android device/emulator connected"
    log_info "Start an emulator first with: emulator -avd <emulator_name>"
    exit 1
fi

log_info "Starting connectivity test..."

# Create reports directory
mkdir -p test_reports

# Start the app in background
log_info "Launching app..."
flutter run -d $($ADB devices | grep "device$" | awk '{print $1}' | head -1) &
APP_PID=$!

sleep 10

# Test 1: Disable connectivity
log_info "Test 1: Disabling connectivity..."
$ADB shell svc wifi disable
$ADB shell svc data disable
log_info "Connectivity disabled - app should detect offline state"
sleep 5

# Take screenshot
$ADB exec-out screencap -p > test_reports/offline_state.png
log_info "Screenshot saved: test_reports/offline_state.png"

# Test 2: Enable connectivity
log_info "Test 2: Enabling connectivity..."
$ADB shell svc wifi enable
$ADB shell svc data enable
log_info "Connectivity enabled - app should detect online state"
sleep 5

# Take screenshot
$ADB exec-out screencap -p > test_reports/online_state.png
log_info "Screenshot saved: test_reports/online_state.png"

# Test 3: Toggle multiple times
log_info "Test 3: Rapid connectivity changes..."
for i in {1..3}; do
    log_info "Toggle $i: Going offline..."
    $ADB shell svc wifi disable
    $ADB shell svc data disable
    sleep 3
    
    log_info "Toggle $i: Going online..."
    $ADB shell svc wifi enable
    $ADB shell svc data enable
    sleep 3
done

# Cleanup
log_info "Restoring connectivity..."
$ADB shell svc wifi enable
$ADB shell svc data enable

log_info "Connectivity test completed!"
log_info "Check screenshots in test_reports/ directory"

# Kill app
kill $APP_PID 2>/dev/null || true
