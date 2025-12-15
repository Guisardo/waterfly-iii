#!/bin/bash

###############################################################################
# Waterfly III E2E Test Runner
#
# This script provides comprehensive E2E testing capabilities:
# - Starts Android emulator
# - Runs integration tests
# - Runs Patrol tests
# - Generates test reports
# - Captures screenshots and logs
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
EMULATOR_NAME="${EMULATOR_NAME:-Pixel_7_API_34}"
ANDROID_API_LEVEL="${ANDROID_API_LEVEL:-34}"
TEST_TIMEOUT="${TEST_TIMEOUT:-600}"
REPORT_DIR="test_reports"
SCREENSHOT_DIR="$REPORT_DIR/screenshots"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed"
        exit 1
    fi
    
    if ! command -v adb &> /dev/null; then
        log_error "ADB is not installed"
        exit 1
    fi
    
    log_info "All dependencies are installed"
}

list_emulators() {
    log_info "Available emulators:"
    emulator -list-avds
}

start_emulator() {
    log_info "Starting Android emulator: $EMULATOR_NAME"
    
    # Check if emulator is already running
    if adb devices | grep -q "emulator"; then
        log_info "Emulator is already running"
        return 0
    fi
    
    # Start emulator in background
    emulator -avd "$EMULATOR_NAME" -no-snapshot-load -no-audio -no-boot-anim &
    EMULATOR_PID=$!
    
    log_info "Waiting for emulator to boot..."
    adb wait-for-device
    
    # Wait for boot to complete
    while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
    done
    
    log_info "Emulator is ready"
}

stop_emulator() {
    log_info "Stopping emulator..."
    adb emu kill
}

setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create report directories
    mkdir -p "$REPORT_DIR"
    mkdir -p "$SCREENSHOT_DIR"
    
    # Get Flutter dependencies
    flutter pub get
    
    # Build test app
    log_info "Building test app..."
    flutter build apk --debug
}

run_integration_tests() {
    log_info "Running integration tests..."
    
    flutter test integration_test/app_test.dart \
        --dart-define=FLUTTER_TEST_TIMEOUT="$TEST_TIMEOUT" \
        --reporter expanded \
        2>&1 | tee "$REPORT_DIR/integration_test.log"
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        log_info "Integration tests passed"
    else
        log_error "Integration tests failed with exit code $exit_code"
    fi
    
    return $exit_code
}

run_patrol_tests() {
    log_info "Running Patrol tests..."
    
    patrol test \
        --target integration_test/patrol_test.dart \
        --verbose \
        2>&1 | tee "$REPORT_DIR/patrol_test.log"
    
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        log_info "Patrol tests passed"
    else
        log_error "Patrol tests failed with exit code $exit_code"
    fi
    
    return $exit_code
}

capture_screenshots() {
    log_info "Capturing screenshots..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    adb exec-out screencap -p > "$SCREENSHOT_DIR/screenshot_$timestamp.png"
}

collect_logs() {
    log_info "Collecting device logs..."
    
    adb logcat -d > "$REPORT_DIR/device_logcat.log"
}

generate_report() {
    log_info "Generating test report..."
    
    cat > "$REPORT_DIR/summary.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Waterfly III E2E Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pass { color: green; }
        .fail { color: red; }
        .section { margin: 20px 0; padding: 10px; border: 1px solid #ccc; }
    </style>
</head>
<body>
    <h1>Waterfly III E2E Test Report</h1>
    <p>Generated: $(date)</p>
    
    <div class="section">
        <h2>Test Results</h2>
        <p>Integration Tests: <span class="$INTEGRATION_STATUS">$INTEGRATION_RESULT</span></p>
        <p>Patrol Tests: <span class="$PATROL_STATUS">$PATROL_RESULT</span></p>
    </div>
    
    <div class="section">
        <h2>Logs</h2>
        <ul>
            <li><a href="integration_test.log">Integration Test Log</a></li>
            <li><a href="patrol_test.log">Patrol Test Log</a></li>
            <li><a href="device_logcat.log">Device Logcat</a></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Screenshots</h2>
        $(ls -1 "$SCREENSHOT_DIR" | sed 's/^/<li><a href="screenshots\/&">&<\/a><\/li>/')
    </div>
</body>
</html>
EOF
    
    log_info "Report generated at $REPORT_DIR/summary.html"
}

cleanup() {
    log_info "Cleaning up..."
    
    if [ "$KEEP_EMULATOR" != "true" ]; then
        stop_emulator
    fi
}

# Main execution
main() {
    log_info "Starting Waterfly III E2E tests"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --emulator)
                EMULATOR_NAME="$2"
                shift 2
                ;;
            --list-emulators)
                list_emulators
                exit 0
                ;;
            --keep-emulator)
                KEEP_EMULATOR=true
                shift
                ;;
            --integration-only)
                RUN_INTEGRATION_ONLY=true
                shift
                ;;
            --patrol-only)
                RUN_PATROL_ONLY=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --emulator NAME         Use specific emulator (default: $EMULATOR_NAME)"
                echo "  --list-emulators        List available emulators"
                echo "  --keep-emulator         Keep emulator running after tests"
                echo "  --integration-only      Run only integration tests"
                echo "  --patrol-only           Run only Patrol tests"
                echo "  --help                  Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Setup trap for cleanup
    trap cleanup EXIT
    
    # Run test pipeline
    check_dependencies
    start_emulator
    setup_test_environment
    
    INTEGRATION_RESULT="SKIPPED"
    PATROL_RESULT="SKIPPED"
    INTEGRATION_STATUS="pass"
    PATROL_STATUS="pass"
    
    if [ "$RUN_PATROL_ONLY" != "true" ]; then
        if run_integration_tests; then
            INTEGRATION_RESULT="PASSED"
        else
            INTEGRATION_RESULT="FAILED"
            INTEGRATION_STATUS="fail"
        fi
    fi
    
    if [ "$RUN_INTEGRATION_ONLY" != "true" ]; then
        if run_patrol_tests; then
            PATROL_RESULT="PASSED"
        else
            PATROL_RESULT="FAILED"
            PATROL_STATUS="fail"
        fi
    fi
    
    capture_screenshots
    collect_logs
    generate_report
    
    log_info "E2E tests completed"
    log_info "Results: Integration=$INTEGRATION_RESULT, Patrol=$PATROL_RESULT"
    
    # Exit with error if any tests failed
    if [ "$INTEGRATION_STATUS" = "fail" ] || [ "$PATROL_STATUS" = "fail" ]; then
        exit 1
    fi
}

# Run main function
main "$@"
