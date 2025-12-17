import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Helper widget for account selection in offline mode.
///
/// Features:
/// - Show sync status for each account
/// - Filter out unsynced accounts if needed
/// - "Create New Account Offline" option
/// - Warning for offline account creation
class AccountSelectionOffline {
  // Reserved for future logging of account selection events
  // ignore: unused_field
  static final Logger _logger = Logger('AccountSelectionOffline');

  /// Build account list tile with sync status
  static Widget buildAccountTile({
    required BuildContext context,
    required String accountName,
    required String accountType,
    required bool isSynced,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        _getAccountIcon(accountType),
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(accountName),
      subtitle: Text(accountType),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isSynced)
            Icon(
              Icons.cloud_off,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Build "Create New Account Offline" option
  static Widget buildCreateAccountOfflineOption({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        title: Text(
          'Create New Account Offline',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Account will sync when online',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        onTap: onTap,
      ),
    );
  }

  /// Show warning dialog for offline account creation
  static Future<bool> showOfflineAccountWarning(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Create Account Offline?'),
            content: const Text(
              'This account will be created locally and synced with the server '
              'when you are back online. You can use it immediately for transactions.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  static IconData _getAccountIcon(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'asset':
        return Icons.account_balance_wallet;
      case 'expense':
        return Icons.shopping_cart;
      case 'revenue':
        return Icons.attach_money;
      case 'liability':
        return Icons.credit_card;
      default:
        return Icons.account_balance;
    }
  }
}

/// Helper widget for category selection in offline mode
class CategorySelectionOffline {
  // Reserved for future logging of category selection events
  // ignore: unused_field
  static final Logger _logger = Logger('CategorySelectionOffline');

  /// Build category list tile with sync status
  static Widget buildCategoryTile({
    required BuildContext context,
    required String categoryName,
    required bool isSynced,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        Icons.category,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(categoryName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isSynced)
            Icon(
              Icons.cloud_off,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  /// Build "Create New Category Offline" option
  static Widget buildCreateCategoryOfflineOption({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        title: Text(
          'Create New Category Offline',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Category will sync when online',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        onTap: onTap,
      ),
    );
  }

  /// Show warning dialog for offline category creation
  static Future<bool> showOfflineCategoryWarning(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Create Category Offline?'),
            content: const Text(
              'This category will be created locally and synced with the server '
              'when you are back online. You can use it immediately for transactions.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create'),
              ),
            ],
          ),
    );

    return result ?? false;
  }
}
