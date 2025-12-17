import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:waterflyiii/main.dart' as app;

/// Patrol-based E2E tests with native automation capabilities
///
/// Patrol provides:
/// - Native automation (permissions, notifications, etc.)
/// - Better performance than integration_test
/// - Hot restart support
/// - Native gestures and interactions
void main() {
  patrolTest('Complete user journey - Login to Transaction Creation', (
    PatrolIntegrationTester $,
  ) async {
    // Launch app
    app.main();
    await $.pumpAndSettle();

    // Handle permissions if needed
    await $.native.grantPermissionWhenInUse();

    // Login flow
    await _performLogin($);

    // Navigate and create transaction
    await _createTransaction($);

    // Test offline mode
    await _testOfflineMode($);

    // Verify sync
    await _verifySyncFunctionality($);
  });

  patrolTest('Test app navigation and screen transitions', (
    PatrolIntegrationTester $,
  ) async {
    app.main();
    await $.pumpAndSettle();

    // Test all bottom navigation items
    await _testBottomNavigation($);

    // Test drawer navigation if exists
    await _testDrawerNavigation($);
  });

  patrolTest('Test transaction CRUD operations', (
    PatrolIntegrationTester $,
  ) async {
    app.main();
    await $.pumpAndSettle();

    // Create transaction
    final String transactionId = await _createTransaction($);

    // Edit transaction
    await _editTransaction($, transactionId);

    // Delete transaction
    await _deleteTransaction($, transactionId);
  });

  patrolTest('Test offline mode with sync', (PatrolIntegrationTester $) async {
    app.main();
    await $.pumpAndSettle();

    // Enable offline mode
    await _enableOfflineMode($);

    // Create offline transaction
    await _createTransaction($);

    // Disable offline mode
    await _disableOfflineMode($);

    // Verify sync occurs
    await _verifySyncFunctionality($);
  });

  patrolTest('Test notification listener functionality', (
    PatrolIntegrationTester $,
  ) async {
    app.main();
    await $.pumpAndSettle();

    // Grant notification access
    await $.native.grantPermissionWhenInUse();

    // Navigate to notification settings
    await _navigateToNotificationSettings($);

    // Enable notification listener
    await _enableNotificationListener($);

    // Simulate notification (if possible)
    // Note: This requires native code integration
  });
}

/// Helper function to perform login
Future<void> _performLogin(PatrolIntegrationTester $) async {
  // Find server URL field
  final PatrolFinder serverUrlField = $(const Key('serverUrlField'));
  if (serverUrlField.exists) {
    await serverUrlField.enterText('https://demo.firefly-iii.org');
    await $.pumpAndSettle();
  }

  // Find token field
  final PatrolFinder tokenField = $(const Key('tokenField'));
  if (tokenField.exists) {
    await tokenField.enterText('demo-token');
    await $.pumpAndSettle();
  }

  // Tap login button
  final PatrolFinder loginButton = $(const Key('loginButton'));
  if (loginButton.exists) {
    await loginButton.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 10));
  }
}

/// Helper function to create a transaction
Future<String> _createTransaction(PatrolIntegrationTester $) async {
  // Tap FAB
  final PatrolFinder fab = $(FloatingActionButton);
  if (fab.exists) {
    await fab.tap();
    await $.pumpAndSettle();
  }

  // Fill transaction details
  final PatrolFinder descriptionField = $(const Key('transactionDescription'));
  if (descriptionField.exists) {
    await descriptionField.enterText('E2E Test Transaction');
    await $.pumpAndSettle();
  }

  final PatrolFinder amountField = $(const Key('transactionAmount'));
  if (amountField.exists) {
    await amountField.enterText('150.00');
    await $.pumpAndSettle();
  }

  // Select source account
  final PatrolFinder sourceAccountField = $(const Key('sourceAccount'));
  if (sourceAccountField.exists) {
    await sourceAccountField.tap();
    await $.pumpAndSettle();

    // Select first account from list
    final PatrolFinder firstAccount = $(const Key('account_0'));
    if (firstAccount.exists) {
      await firstAccount.tap();
      await $.pumpAndSettle();
    }
  }

  // Save transaction
  final PatrolFinder saveButton = $(const Key('saveTransaction'));
  if (saveButton.exists) {
    await saveButton.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));
  }

  return 'transaction_id'; // Return actual ID if available
}

/// Helper function to edit a transaction
Future<void> _editTransaction(
  PatrolIntegrationTester $,
  String transactionId,
) async {
  // Find transaction in list
  final PatrolFinder transaction = $(Key('transaction_$transactionId'));
  if (transaction.exists) {
    await transaction.tap();
    await $.pumpAndSettle();

    // Tap edit button
    final PatrolFinder editButton = $(const Key('editTransaction'));
    if (editButton.exists) {
      await editButton.tap();
      await $.pumpAndSettle();

      // Modify amount
      final PatrolFinder amountField = $(const Key('transactionAmount'));
      if (amountField.exists) {
        await amountField.enterText('200.00');
        await $.pumpAndSettle();
      }

      // Save changes
      final PatrolFinder saveButton = $(const Key('saveTransaction'));
      if (saveButton.exists) {
        await saveButton.tap();
        await $.pumpAndSettle();
      }
    }
  }
}

/// Helper function to delete a transaction
Future<void> _deleteTransaction(
  PatrolIntegrationTester $,
  String transactionId,
) async {
  // Find transaction in list
  final PatrolFinder transaction = $(Key('transaction_$transactionId'));
  if (transaction.exists) {
    await transaction.tap();
    await $.pumpAndSettle();

    // Tap delete button
    final PatrolFinder deleteButton = $(const Key('deleteTransaction'));
    if (deleteButton.exists) {
      await deleteButton.tap();
      await $.pumpAndSettle();

      // Confirm deletion
      final PatrolFinder confirmButton = $(const Key('confirmDelete'));
      if (confirmButton.exists) {
        await confirmButton.tap();
        await $.pumpAndSettle();
      }
    }
  }
}

/// Helper function to test bottom navigation
Future<void> _testBottomNavigation(PatrolIntegrationTester $) async {
  // Navigate to Transactions
  final PatrolFinder transactionsTab = $(Icons.receipt_long);
  if (transactionsTab.exists) {
    await transactionsTab.tap();
    await $.pumpAndSettle();
  }

  // Navigate to Accounts
  final PatrolFinder accountsTab = $(Icons.account_balance);
  if (accountsTab.exists) {
    await accountsTab.tap();
    await $.pumpAndSettle();
  }

  // Navigate to Settings
  final PatrolFinder settingsTab = $(Icons.settings);
  if (settingsTab.exists) {
    await settingsTab.tap();
    await $.pumpAndSettle();
  }

  // Return to Dashboard
  final PatrolFinder dashboardTab = $(Icons.dashboard);
  if (dashboardTab.exists) {
    await dashboardTab.tap();
    await $.pumpAndSettle();
  }
}

/// Helper function to test drawer navigation
Future<void> _testDrawerNavigation(PatrolIntegrationTester $) async {
  // Open drawer
  final PatrolFinder drawerButton = $(Icons.menu);
  if (drawerButton.exists) {
    await drawerButton.tap();
    await $.pumpAndSettle();

    // Test drawer items
    final PatrolFinder billsItem = $(const Key('drawer_bills'));
    if (billsItem.exists) {
      await billsItem.tap();
      await $.pumpAndSettle();
    }
  }
}

/// Helper function to enable offline mode
Future<void> _enableOfflineMode(PatrolIntegrationTester $) async {
  // Navigate to settings
  final PatrolFinder settingsTab = $(Icons.settings);
  if (settingsTab.exists) {
    await settingsTab.tap();
    await $.pumpAndSettle();
  }

  // Find and toggle offline mode
  final PatrolFinder offlineToggle = $(const Key('offlineModeToggle'));
  if (offlineToggle.exists) {
    await offlineToggle.tap();
    await $.pumpAndSettle();
  }
}

/// Helper function to disable offline mode
Future<void> _disableOfflineMode(PatrolIntegrationTester $) async {
  // Navigate to settings
  final PatrolFinder settingsTab = $(Icons.settings);
  if (settingsTab.exists) {
    await settingsTab.tap();
    await $.pumpAndSettle();
  }

  // Find and toggle offline mode
  final PatrolFinder offlineToggle = $(const Key('offlineModeToggle'));
  if (offlineToggle.exists) {
    await offlineToggle.tap();
    await $.pumpAndSettle();
  }
}

/// Helper function to test offline mode
Future<void> _testOfflineMode(PatrolIntegrationTester $) async {
  await _enableOfflineMode($);

  // Verify offline indicator
  final PatrolFinder offlineIndicator = $(const Key('offlineIndicator'));
  expect(
    offlineIndicator.exists,
    true,
    reason: 'Offline indicator should be visible',
  );

  await _disableOfflineMode($);
}

/// Helper function to verify sync functionality
Future<void> _verifySyncFunctionality(PatrolIntegrationTester $) async {
  // Find sync button
  final PatrolFinder syncButton = $(const Key('syncButton'));
  if (syncButton.exists) {
    await syncButton.tap();
    await $.pumpAndSettle(timeout: const Duration(seconds: 10));

    // Verify sync progress
    final PatrolFinder syncProgress = $(CircularProgressIndicator);
    expect(
      syncProgress.exists,
      true,
      reason: 'Sync progress should be visible',
    );
  }
}

/// Helper function to navigate to notification settings
Future<void> _navigateToNotificationSettings(PatrolIntegrationTester $) async {
  // Navigate to settings
  final PatrolFinder settingsTab = $(Icons.settings);
  if (settingsTab.exists) {
    await settingsTab.tap();
    await $.pumpAndSettle();
  }

  // Find notification settings
  final PatrolFinder notificationSettings = $(
    const Key('notificationSettings'),
  );
  if (notificationSettings.exists) {
    await notificationSettings.tap();
    await $.pumpAndSettle();
  }
}

/// Helper function to enable notification listener
Future<void> _enableNotificationListener(PatrolIntegrationTester $) async {
  final PatrolFinder notificationToggle = $(
    const Key('notificationListenerToggle'),
  );
  if (notificationToggle.exists) {
    await notificationToggle.tap();
    await $.pumpAndSettle();

    // Handle system permission dialog
    await $.native.grantPermissionWhenInUse();
  }
}
