import 'dart:io';
import 'package:flutter/foundation.dart';

/// Test configuration for E2E tests
/// 
/// Provides:
/// - Test environment settings
/// - Mock data for testing
/// - Helper utilities for test setup
class TestConfig {
  /// Demo server URL for testing
  static const String demoServerUrl = 'https://demo.firefly-iii.org';

  /// Demo access token
  static const String demoToken = 'demo-token';

  /// Test timeout durations
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);

  /// Test user credentials
  static const Map<String, String> testCredentials = <String, String>{
    'serverUrl': demoServerUrl,
    'token': demoToken,
  };

  /// Mock transaction data
  static const Map<String, dynamic> mockTransaction = <String, dynamic>{
    'description': 'E2E Test Transaction',
    'amount': '100.00',
    'type': 'withdrawal',
    'date': '2024-12-14',
  };

  /// Mock account data
  static const Map<String, dynamic> mockAccount = <String, dynamic>{
    'name': 'Test Account',
    'type': 'asset',
    'currency': 'USD',
    'balance': '1000.00',
  };

  /// Check if running in CI environment
  static bool get isCI => kIsWeb || Platform.environment.containsKey('CI');

  /// Get appropriate timeout based on environment
  static Duration getTimeout({bool isLongRunning = false}) {
    if (isCI) {
      return isLongRunning ? longTimeout * 2 : mediumTimeout * 2;
    }
    return isLongRunning ? longTimeout : mediumTimeout;
  }
}

/// Helper class for test utilities
class TestHelpers {
  /// Wait for a specific condition to be true
  static Future<void> waitForCondition(
    Future<bool> Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final DateTime endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (await condition()) {
        return;
      }
      await Future.delayed(pollInterval);
    }

    throw TimeoutException('Condition not met within $timeout');
  }

  /// Generate unique test identifier
  static String generateTestId() {
    return 'test_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    // Implement cleanup logic
    debugPrint('Cleaning up test data...');
  }
}

/// Exception for test timeouts
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
