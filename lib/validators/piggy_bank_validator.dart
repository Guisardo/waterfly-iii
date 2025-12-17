import 'package:logging/logging.dart';

import 'package:waterflyiii/validators/transaction_validator.dart';

/// Validates piggy bank data before storage or synchronization.
class PiggyBankValidator {
  final Logger _logger = Logger('PiggyBankValidator');

  /// Validates piggy bank data
  Future<ValidationResult> validate(
    Map<String, dynamic> data, {
    Future<bool> Function(String)? accountExists,
  }) async {
    _logger.fine('Validating piggy bank data');

    final List<String> errors = <String>[];

    // Required fields
    if (!data.containsKey('name') ||
        data['name'] == null ||
        (data['name'] as String).trim().isEmpty) {
      errors.add('Piggy bank name is required');
    } else {
      final String name = (data['name'] as String).trim();
      if (name.length > 255) {
        errors.add('Piggy bank name exceeds maximum length of 255 characters');
      }
    }

    // Account validation
    if (!data.containsKey('account_id') || data['account_id'] == null) {
      errors.add('Account ID is required');
    } else {
      final String accountId = data['account_id'] as String;
      if (accountExists != null && !await accountExists(accountId)) {
        errors.add('Associated account not found: $accountId');
      }
    }

    // Target amount validation
    if (data.containsKey('target_amount') && data['target_amount'] != null) {
      final double? targetAmount = _parseAmount(data['target_amount']);
      if (targetAmount == null) {
        errors.add('Target amount must be a valid number');
      } else if (targetAmount <= 0) {
        errors.add('Target amount must be greater than zero');
      } else if (targetAmount > 999999999.99) {
        errors.add('Target amount exceeds maximum allowed value');
      }
    }

    // Current amount validation
    if (data.containsKey('current_amount') && data['current_amount'] != null) {
      final double? currentAmount = _parseAmount(data['current_amount']);
      if (currentAmount == null) {
        errors.add('Current amount must be a valid number');
      } else if (currentAmount < 0) {
        errors.add('Current amount cannot be negative');
      }

      // Check if current exceeds target
      if (data.containsKey('target_amount') && data['target_amount'] != null) {
        final double? targetAmount = _parseAmount(data['target_amount']);
        if (targetAmount != null && (currentAmount ?? 0) > targetAmount) {
          _logger.warning('Current amount exceeds target amount');
          // Don't error - this is allowed
        }
      }
    }

    // Date validation
    if (data.containsKey('start_date') && data['start_date'] != null) {
      final DateTime? startDate = _parseDate(data['start_date']);
      if (startDate == null) {
        errors.add('Invalid start date format');
      }
    }

    if (data.containsKey('target_date') && data['target_date'] != null) {
      final DateTime? targetDate = _parseDate(data['target_date']);
      if (targetDate == null) {
        errors.add('Invalid target date format');
      }

      if (data.containsKey('start_date') && data['start_date'] != null) {
        final DateTime? startDate = _parseDate(data['start_date']);
        if (startDate != null && (targetDate?.isBefore(startDate) ?? false)) {
          errors.add('Target date must be after start date');
        }
      }
    }

    final bool isValid = errors.isEmpty;
    if (!isValid) {
      _logger.warning('Piggy bank validation failed: ${errors.join(', ')}');
    }

    return ValidationResult(isValid: isValid, errors: errors);
  }

  /// Validates adding money to piggy bank
  ValidationResult validateAddMoney(
    double amount,
    double currentAmount,
    double? targetAmount,
  ) {
    _logger.fine('Validating add money operation');

    final List<String> errors = <String>[];

    if (amount <= 0) {
      errors.add('Amount must be greater than zero');
    }

    if (amount > 999999999.99) {
      errors.add('Amount exceeds maximum allowed value');
    }

    final double newAmount = currentAmount + amount;
    if (targetAmount != null && newAmount > targetAmount) {
      _logger.warning('Adding money will exceed target amount');
      // Don't error - this is allowed
    }

    final bool isValid = errors.isEmpty;
    return ValidationResult(isValid: isValid, errors: errors);
  }

  /// Validates removing money from piggy bank
  ValidationResult validateRemoveMoney(double amount, double currentAmount) {
    _logger.fine('Validating remove money operation');

    final List<String> errors = <String>[];

    if (amount <= 0) {
      errors.add('Amount must be greater than zero');
    }

    if (amount > currentAmount) {
      errors.add('Cannot remove more than current amount');
    }

    final bool isValid = errors.isEmpty;
    return ValidationResult(isValid: isValid, errors: errors);
  }

  double? _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
