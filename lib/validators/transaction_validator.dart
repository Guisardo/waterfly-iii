import 'package:logging/logging.dart';

import 'package:waterflyiii/exceptions/offline_exceptions.dart';

/// Validates transaction data before storage or synchronization.
///
/// Ensures all required fields are present, values are within valid ranges,
/// and business rules are satisfied.
///
/// Example:
/// ```dart
/// final validator = TransactionValidator();
///
/// final result = validator.validate(transactionData);
/// if (!result.isValid) {
///   print('Validation errors: ${result.errors}');
/// }
/// ```
class TransactionValidator {
  final Logger _logger = Logger('TransactionValidator');

  /// Validates transaction data
  ///
  /// Returns [ValidationResult] with isValid flag and list of errors
  ValidationResult validate(Map<String, dynamic> data) {
    _logger.fine('Validating transaction data');

    final List<String> errors = <String>[];

    // Required fields validation
    if (!data.containsKey('type') || data['type'] == null) {
      errors.add('Transaction type is required');
    } else {
      final String type = data['type'] as String;
      if (!<String>[
        'withdrawal',
        'deposit',
        'transfer',
      ].contains(type.toLowerCase())) {
        errors.add(
          'Invalid transaction type: $type. '
          'Must be withdrawal, deposit, or transfer',
        );
      }
    }

    if (!data.containsKey('amount') || data['amount'] == null) {
      errors.add('Amount is required');
    } else {
      final double? amount = _parseAmount(data['amount']);
      if (amount == null) {
        errors.add('Amount must be a valid number');
      } else if (amount <= 0) {
        errors.add('Amount must be greater than zero');
      } else if (amount > 999999999.99) {
        errors.add('Amount exceeds maximum allowed value');
      }
    }

    if (!data.containsKey('date') || data['date'] == null) {
      errors.add('Transaction date is required');
    } else {
      final DateTime? date = _parseDate(data['date']);
      if (date == null) {
        errors.add('Invalid date format');
      } else if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        errors.add('Transaction date cannot be in the future');
      }
    }

    if (!data.containsKey('description') ||
        data['description'] == null ||
        (data['description'] as String).trim().isEmpty) {
      errors.add('Description is required');
    } else {
      final String description = data['description'] as String;
      if (description.length > 1000) {
        errors.add('Description exceeds maximum length of 1000 characters');
      }
    }

    // Account validation
    final String? type = data['type'] as String?;
    if (type != null) {
      if (type.toLowerCase() == 'withdrawal' ||
          type.toLowerCase() == 'transfer') {
        if (!data.containsKey('source_id') || data['source_id'] == null) {
          errors.add('Source account is required for $type transactions');
        }
      }

      if (type.toLowerCase() == 'deposit' || type.toLowerCase() == 'transfer') {
        if (!data.containsKey('destination_id') ||
            data['destination_id'] == null) {
          errors.add('Destination account is required for $type transactions');
        }
      }

      if (type.toLowerCase() == 'transfer') {
        if (data['source_id'] == data['destination_id']) {
          errors.add(
            'Source and destination accounts must be different for transfers',
          );
        }
      }
    }

    // Currency validation
    if (data.containsKey('currency_code') && data['currency_code'] != null) {
      final String currencyCode = data['currency_code'] as String;
      if (!_isValidCurrencyCode(currencyCode)) {
        errors.add('Invalid currency code: $currencyCode');
      }
    }

    // Foreign amount validation (for multi-currency transactions)
    if (data.containsKey('foreign_amount') && data['foreign_amount'] != null) {
      final double? foreignAmount = _parseAmount(data['foreign_amount']);
      if (foreignAmount == null) {
        errors.add('Foreign amount must be a valid number');
      } else if (foreignAmount <= 0) {
        errors.add('Foreign amount must be greater than zero');
      }

      if (!data.containsKey('foreign_currency_code') ||
          data['foreign_currency_code'] == null) {
        errors.add(
          'Foreign currency code is required when foreign amount is specified',
        );
      }
    }

    // Budget validation
    if (data.containsKey('budget_id') && data['budget_id'] != null) {
      final budgetId = data['budget_id'];
      if (budgetId is! String || budgetId.isEmpty) {
        errors.add('Invalid budget ID');
      }
    }

    // Category validation
    if (data.containsKey('category_id') && data['category_id'] != null) {
      final categoryId = data['category_id'];
      if (categoryId is! String || categoryId.isEmpty) {
        errors.add('Invalid category ID');
      }
    }

    // Tags validation
    if (data.containsKey('tags') && data['tags'] != null) {
      if (data['tags'] is! List) {
        errors.add('Tags must be a list');
      } else {
        final List<dynamic> tags = data['tags'] as List;
        if (tags.length > 50) {
          errors.add('Maximum 50 tags allowed');
        }
        for (final tag in tags) {
          if (tag is! String || tag.isEmpty) {
            errors.add('Invalid tag value');
            break;
          }
        }
      }
    }

    final bool isValid = errors.isEmpty;

    if (!isValid) {
      _logger.warning('Transaction validation failed: ${errors.join(', ')}');
    } else {
      _logger.fine('Transaction validation passed');
    }

    return ValidationResult(isValid: isValid, errors: errors);
  }

  /// Validates that required account references exist
  ///
  /// This should be called after basic validation to ensure
  /// referenced accounts are present in the local database.
  Future<ValidationResult> validateAccountReferences(
    Map<String, dynamic> data,
    Future<bool> Function(String) accountExists,
  ) async {
    _logger.fine('Validating account references');

    final List<String> errors = <String>[];

    if (data.containsKey('source_id') && data['source_id'] != null) {
      final String sourceId = data['source_id'] as String;
      if (!await accountExists(sourceId)) {
        errors.add('Source account not found: $sourceId');
      }
    }

    if (data.containsKey('destination_id') && data['destination_id'] != null) {
      final String destinationId = data['destination_id'] as String;
      if (!await accountExists(destinationId)) {
        errors.add('Destination account not found: $destinationId');
      }
    }

    final bool isValid = errors.isEmpty;

    if (!isValid) {
      _logger.warning(
        'Account reference validation failed: ${errors.join(', ')}',
      );
    }

    return ValidationResult(isValid: isValid, errors: errors);
  }

  // Private helper methods

  double? _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  bool _isValidCurrencyCode(String code) {
    // ISO 4217 currency codes are 3 uppercase letters
    if (code.length != 3) return false;
    if (code != code.toUpperCase()) return false;
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) return false;

    // Common currency codes (not exhaustive, but covers most cases)
    const Set<String> commonCurrencies = <String>{
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CHF',
      'CAD',
      'AUD',
      'NZD',
      'CNY',
      'INR',
      'BRL',
      'RUB',
      'KRW',
      'MXN',
      'ZAR',
      'SEK',
      'NOK',
      'DKK',
      'PLN',
      'THB',
      'IDR',
      'HUF',
      'CZK',
      'ILS',
      'CLP',
      'PHP',
      'AED',
      'COP',
      'SAR',
      'MYR',
      'RON',
      'ARS',
    };

    return commonCurrencies.contains(code);
  }
}

/// Result of a validation operation
class ValidationResult {
  /// Whether the validation passed
  final bool isValid;

  /// List of validation error messages
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});

  /// Throws ValidationException if validation failed
  void throwIfInvalid() {
    if (!isValid) {
      throw ValidationException(errors.join('; '));
    }
  }

  @override
  String toString() {
    if (isValid) return 'ValidationResult(valid)';
    return 'ValidationResult(invalid: ${errors.join(', ')})';
  }
}
