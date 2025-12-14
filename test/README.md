# Testing Guide

This directory contains tests for Waterfly III offline mode features.

## Test Structure

```
test/
├── widgets/              # Widget tests
│   ├── connectivity_status_bar_test.dart
│   └── sync_status_indicator_test.dart
├── services/             # Service/unit tests
│   ├── accessibility_service_test.dart
│   └── visual_accessibility_service_test.dart
└── integration/          # Integration tests
    └── offline_transaction_test.dart
```

## Running Tests

### All Tests
```bash
flutter test
```

### Widget Tests Only
```bash
flutter test test/widgets/
```

### Service Tests Only
```bash
flutter test test/services/
```

### Integration Tests
```bash
flutter test integration_test/
```

### With Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Categories

### Widget Tests
Test individual UI components in isolation:
- Rendering correctness
- User interactions
- State changes
- Accessibility labels
- Animations

**Coverage Target**: >80%

### Service Tests
Test business logic and services:
- Accessibility service
- Visual accessibility service
- Animation service
- Sync services

**Coverage Target**: >90%

### Integration Tests
Test complete user flows:
- Offline transaction creation
- Sync process
- Conflict resolution
- Connectivity changes

**Coverage Target**: >70%

## Writing Tests

### Widget Test Template
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyWidget Tests', () {
    testWidgets('description', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MyWidget(),
          ),
        ),
      );

      expect(find.byType(MyWidget), findsOneWidget);
    });
  });
}
```

### Service Test Template
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyService Tests', () {
    late MyService service;

    setUp(() {
      service = MyService();
    });

    test('description', () {
      final result = service.doSomething();
      expect(result, expectedValue);
    });
  });
}
```

## Accessibility Testing

### Semantic Labels
```dart
testWidgets('has semantic labels', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  
  final semantics = tester.getSemantics(find.byType(MyWidget));
  expect(semantics.label, isNotEmpty);
});
```

### Screen Reader Announcements
```dart
test('announces connectivity change', () {
  final service = AccessibilityService();
  service.announceConnectivityChange(isOnline: false);
  // Verify announcement was made
});
```

## Mocking

Use `mockito` for mocking dependencies:

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([SyncManager])
void main() {
  late MockSyncManager mockSyncManager;

  setUp(() {
    mockSyncManager = MockSyncManager();
  });

  test('uses mocked service', () {
    when(mockSyncManager.sync()).thenAnswer((_) async => true);
    // Test with mock
  });
}
```

## CI/CD Integration

Tests run automatically on:
- Pull requests
- Commits to main branch
- Release builds

### GitHub Actions
```yaml
- name: Run tests
  run: flutter test --coverage
  
- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

## Troubleshooting

### Tests Timing Out
Increase timeout:
```dart
testWidgets('test', (WidgetTester tester) async {
  // ...
}, timeout: const Timeout(Duration(minutes: 2)));
```

### Pump and Settle Issues
Use `pumpAndSettle` with duration:
```dart
await tester.pumpAndSettle(const Duration(seconds: 5));
```

### Golden File Tests
Update golden files:
```bash
flutter test --update-goldens
```

## Coverage Goals

| Category | Target | Current |
|----------|--------|---------|
| Overall | >80% | TBD |
| Widgets | >80% | TBD |
| Services | >90% | TBD |
| Integration | >70% | TBD |

## Manual Testing Checklist

- [ ] TalkBack on Android
- [ ] VoiceOver on iOS
- [ ] Large text sizes (200%)
- [ ] High contrast mode
- [ ] External keyboard
- [ ] Switch control
- [ ] Different screen sizes
- [ ] Tablet layouts
- [ ] Offline mode
- [ ] Sync process
- [ ] Conflict resolution

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito](https://pub.dev/packages/mockito)

---

Last updated: 2025-12-14
