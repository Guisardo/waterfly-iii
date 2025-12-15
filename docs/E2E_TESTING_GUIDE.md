# Waterfly III E2E Testing Guide

## Overview

This guide provides comprehensive instructions for running end-to-end (E2E) tests for the Waterfly III Flutter application using both `integration_test` (Flutter's official solution) and `patrol` (enhanced testing framework).

## Prerequisites

### Required Software

1. **Flutter SDK** (3.7.0 or higher)
   ```bash
   flutter --version
   ```

2. **Android Studio** with Android SDK
   - Android SDK Platform-Tools
   - Android Emulator
   - Android SDK Build-Tools

3. **Xcode** (for iOS testing - macOS only)
   - Xcode Command Line Tools
   - iOS Simulator

### Setup

1. **Install Dependencies**
   ```bash
   cd /path/to/waterfly-iii
   flutter pub get
   ```

2. **Install Patrol CLI** (for Patrol tests)
   ```bash
   dart pub global activate patrol_cli
   ```

3. **Verify Installation**
   ```bash
   flutter doctor
   patrol doctor
   ```

## Test Structure

```
waterfly-iii/
├── integration_test/
│   ├── app_test.dart           # Main integration tests
│   ├── patrol_test.dart        # Patrol-based tests
│   └── test_config.dart        # Test configuration
├── android/
│   └── app/src/androidTest/    # Android-specific tests
├── run_e2e_tests.sh            # Test runner script
└── docs/
    └── E2E_TESTING_GUIDE.md    # This file
```

## Running Tests

### Option 1: Using the Test Runner Script (Recommended)

The `run_e2e_tests.sh` script provides automated test execution with emulator management:

```bash
# Run all tests
./run_e2e_tests.sh

# List available emulators
./run_e2e_tests.sh --list-emulators

# Use specific emulator
./run_e2e_tests.sh --emulator Pixel_7_API_34

# Run only integration tests
./run_e2e_tests.sh --integration-only

# Run only Patrol tests
./run_e2e_tests.sh --patrol-only

# Keep emulator running after tests
./run_e2e_tests.sh --keep-emulator
```

### Option 2: Manual Test Execution

#### Integration Tests

```bash
# Start Android emulator
emulator -avd Pixel_7_API_34 &

# Wait for emulator to boot
adb wait-for-device

# Run integration tests
flutter test integration_test/app_test.dart
```

#### Patrol Tests

```bash
# Run Patrol tests on Android
patrol test --target integration_test/patrol_test.dart

# Run on specific device
patrol test --target integration_test/patrol_test.dart --device <device-id>

# Run with verbose output
patrol test --target integration_test/patrol_test.dart --verbose
```

### Option 3: IDE Integration

#### Android Studio / IntelliJ IDEA

1. Open `integration_test/app_test.dart`
2. Click the green play button next to the test
3. Select "Run 'app_test.dart'"

#### VS Code

1. Install Flutter extension
2. Open `integration_test/app_test.dart`
3. Click "Run" above the test function
4. Or use Command Palette: "Flutter: Run Integration Tests"

## Test Configuration

### Environment Variables

```bash
# Set test timeout (seconds)
export TEST_TIMEOUT=600

# Set emulator name
export EMULATOR_NAME=Pixel_7_API_34

# Set Android API level
export ANDROID_API_LEVEL=34
```

### Test Config File

Edit `integration_test/test_config.dart` to customize:

```dart
class TestConfig {
  static const String demoServerUrl = 'https://demo.firefly-iii.org';
  static const String demoToken = 'demo-token';
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);
}
```

## Test Scenarios

### 1. App Launch and Initialization

Tests that the app launches correctly and shows the appropriate initial screen.

```dart
testWidgets('App launches and shows splash screen', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  expect(find.byType(MaterialApp), findsOneWidget);
});
```

### 2. Login Flow

Tests user authentication with valid and invalid credentials.

```dart
testWidgets('Login flow with valid credentials', (tester) async {
  // Enter server URL
  await tester.enterText(find.byKey(Key('serverUrlField')), serverUrl);
  
  // Enter token
  await tester.enterText(find.byKey(Key('tokenField')), token);
  
  // Tap login
  await tester.tap(find.byKey(Key('loginButton')));
  await tester.pumpAndSettle();
  
  // Verify navigation to home
  expect(find.byType(BottomNavigationBar), findsOneWidget);
});
```

### 3. Navigation

Tests navigation between different screens.

```dart
testWidgets('Navigate through main screens', (tester) async {
  // Navigate to Transactions
  await tester.tap(find.byIcon(Icons.receipt_long));
  await tester.pumpAndSettle();
  
  // Navigate to Accounts
  await tester.tap(find.byIcon(Icons.account_balance));
  await tester.pumpAndSettle();
});
```

### 4. Transaction CRUD Operations

Tests creating, reading, updating, and deleting transactions.

```dart
testWidgets('Create new transaction', (tester) async {
  // Tap FAB
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  
  // Fill form
  await tester.enterText(find.byKey(Key('transactionDescription')), 'Test');
  await tester.enterText(find.byKey(Key('transactionAmount')), '100.00');
  
  // Save
  await tester.tap(find.byKey(Key('saveTransaction')));
  await tester.pumpAndSettle();
});
```

### 5. Offline Mode

Tests offline functionality and synchronization.

```dart
testWidgets('Test offline mode toggle', (tester) async {
  // Navigate to settings
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();
  
  // Toggle offline mode
  await tester.tap(find.byKey(Key('offlineModeToggle')));
  await tester.pumpAndSettle();
  
  // Verify offline indicator
  expect(find.text('Offline Mode'), findsOneWidget);
});
```

## Patrol-Specific Features

### Native Automation

Patrol provides native automation capabilities:

```dart
patrolTest('Handle permissions', ($) async {
  // Grant notification permission
  await $.native.grantPermissionWhenInUse();
  
  // Open app settings
  await $.native.openAppSettings();
  
  // Press back button
  await $.native.pressBack();
});
```

### Better Selectors

```dart
// Find by Key
final button = $(Key('myButton'));

// Find by Type
final fab = $(FloatingActionButton);

// Find by Icon
final settingsIcon = $(Icons.settings);

// Find by Text
final title = $(#'Dashboard');
```

### Hot Restart Support

Patrol supports hot restart during test development:

```bash
patrol develop --target integration_test/patrol_test.dart
```

## Debugging Tests

### Enable Verbose Logging

```bash
flutter test integration_test/app_test.dart --verbose
```

### Capture Screenshots

```dart
testWidgets('My test', (tester) async {
  // ... test code ...
  
  // Capture screenshot
  await tester.takeScreenshot('my_test_screenshot');
});
```

### View Device Logs

```bash
# Android
adb logcat

# iOS
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"'
```

### Debug Mode

Run tests in debug mode to use breakpoints:

```bash
flutter run integration_test/app_test.dart --debug
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e-tests:
    runs-on: macos-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.7.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run E2E tests
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          target: google_apis
          arch: x86_64
          script: ./run_e2e_tests.sh
      
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-reports
          path: test_reports/
```

## Best Practices

### 1. Use Keys for Important Widgets

```dart
TextField(
  key: Key('emailField'),
  // ...
)
```

### 2. Wait for Animations

```dart
await tester.pumpAndSettle();
```

### 3. Use Semantic Labels

```dart
IconButton(
  icon: Icon(Icons.settings),
  semanticLabel: 'Settings',
  // ...
)
```

### 4. Test in Isolation

Each test should be independent and not rely on other tests.

### 5. Clean Up After Tests

```dart
tearDown(() async {
  await TestHelpers.cleanupTestData();
});
```

### 6. Use Page Objects

Create page object classes for complex screens:

```dart
class LoginPage {
  final WidgetTester tester;
  
  LoginPage(this.tester);
  
  Future<void> enterServerUrl(String url) async {
    await tester.enterText(find.byKey(Key('serverUrlField')), url);
  }
  
  Future<void> enterToken(String token) async {
    await tester.enterText(find.byKey(Key('tokenField')), token);
  }
  
  Future<void> tapLogin() async {
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();
  }
}
```

## Troubleshooting

### Emulator Won't Start

```bash
# List available emulators
emulator -list-avds

# Create new emulator
avdmanager create avd -n Pixel_7_API_34 -k "system-images;android-34;google_apis;x86_64"
```

### Tests Timeout

Increase timeout in test configuration:

```dart
testWidgets('My test', (tester) async {
  // ...
}, timeout: Timeout(Duration(minutes: 5)));
```

### Widget Not Found

Add delays or use `pumpAndSettle`:

```dart
await tester.pumpAndSettle(Duration(seconds: 2));
```

### Permission Issues

Ensure app has required permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Patrol Documentation](https://patrol.leancode.co/)
- [Flutter Testing Best Practices](https://docs.flutter.dev/testing/best-practices)
- [Android Testing Guide](https://developer.android.com/training/testing)

## Support

For issues or questions:
1. Check existing GitHub issues
2. Review test logs in `test_reports/`
3. Enable verbose logging
4. Create a new issue with:
   - Test output
   - Device logs
   - Screenshots
   - Steps to reproduce
