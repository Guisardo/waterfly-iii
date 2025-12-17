import 'package:logging/logging.dart';

import 'package:waterflyiii/validators/transaction_validator.dart';

/// Validates account data before storage or synchronization.
///
/// Ensures account names are unique, types are valid, and
/// business rules are satisfied.
///
/// Example:
/// ```dart
/// final validator = AccountValidator();
///
/// final result = await validator.validate(accountData, checkNameExists);
/// if (!result.isValid) {
///   print('Validation errors: ${result.errors}');
/// }
/// ```
class AccountValidator {
  final Logger _logger = Logger('AccountValidator');

  /// Valid account types in Firefly III
  static const List<String> validAccountTypes = <String>[
    'asset',
    'expense',
    'revenue',
    'cash',
    'loan',
    'debt',
    'mortgage',
    'initial-balance',
    'reconciliation',
  ];

  /// Valid account roles
  static const List<String> validAccountRoles = <String>[
    'defaultAsset',
    'sharedAsset',
    'savingAsset',
    'ccAsset',
    'cashWalletAsset',
  ];

  /// Validates account data
  ///
  /// Checks required fields, valid types, and business rules.
  /// Optionally checks for duplicate names.
  ///
  /// Returns [ValidationResult] with isValid flag and list of errors
  Future<ValidationResult> validate(
    Map<String, dynamic> data, {
    Future<bool> Function(String)? nameExists,
    String? excludeAccountId,
  }) async {
    _logger.fine('Validating account data');

    final List<String> errors = <String>[];

    // Required fields validation
    if (!data.containsKey('name') ||
        data['name'] == null ||
        (data['name'] as String).trim().isEmpty) {
      errors.add('Account name is required');
    } else {
      final String name = (data['name'] as String).trim();

      if (name.isEmpty) {
        errors.add('Account name cannot be empty');
      } else if (name.length > 255) {
        errors.add('Account name exceeds maximum length of 255 characters');
      }

      // Check for duplicate names
      if (nameExists != null) {
        final bool exists = await nameExists(name);
        if (exists) {
          errors.add('An account with name "$name" already exists');
        }
      }
    }

    if (!data.containsKey('type') || data['type'] == null) {
      errors.add('Account type is required');
    } else {
      final String type = (data['type'] as String).toLowerCase();
      if (!validAccountTypes.contains(type)) {
        errors.add(
          'Invalid account type: $type. '
          'Must be one of: ${validAccountTypes.join(', ')}',
        );
      }
    }

    // Currency validation
    if (data.containsKey('currency_code') && data['currency_code'] != null) {
      final String currencyCode = data['currency_code'] as String;
      if (!_isValidCurrencyCode(currencyCode)) {
        errors.add('Invalid currency code: $currencyCode');
      }
    } else {
      // Currency is required for asset accounts
      final String? type = data['type'] as String?;
      if (type != null && type.toLowerCase() == 'asset') {
        errors.add('Currency code is required for asset accounts');
      }
    }

    // Opening balance validation
    if (data.containsKey('opening_balance') &&
        data['opening_balance'] != null) {
      final double? openingBalance = _parseAmount(data['opening_balance']);
      if (openingBalance == null) {
        errors.add('Opening balance must be a valid number');
      } else if (openingBalance.abs() > 999999999.99) {
        errors.add('Opening balance exceeds maximum allowed value');
      }

      // Opening balance date is required if opening balance is set
      if (!data.containsKey('opening_balance_date') ||
          data['opening_balance_date'] == null) {
        errors.add(
          'Opening balance date is required when opening balance is set',
        );
      } else {
        final DateTime? date = _parseDate(data['opening_balance_date']);
        if (date == null) {
          errors.add('Invalid opening balance date format');
        } else if (date.isAfter(DateTime.now())) {
          errors.add('Opening balance date cannot be in the future');
        }
      }
    }

    // Account role validation
    if (data.containsKey('account_role') && data['account_role'] != null) {
      final String role = data['account_role'] as String;
      if (!validAccountRoles.contains(role)) {
        errors.add(
          'Invalid account role: $role. '
          'Must be one of: ${validAccountRoles.join(', ')}',
        );
      }
    }

    // Credit card specific validations
    final String? type = data['type'] as String?;
    if (type != null && type.toLowerCase() == 'asset') {
      final String? role = data['account_role'] as String?;
      if (role == 'ccAsset') {
        // Credit card accounts should have monthly payment date
        if (data.containsKey('monthly_payment_date') &&
            data['monthly_payment_date'] != null) {
          final paymentDate = data['monthly_payment_date'];
          if (paymentDate is! String || paymentDate.isEmpty) {
            errors.add('Invalid monthly payment date format');
          }
        }

        // Credit card accounts should have credit card type
        if (data.containsKey('credit_card_type') &&
            data['credit_card_type'] != null) {
          final String ccType = data['credit_card_type'] as String;
          if (!<String>['monthlyFull'].contains(ccType)) {
            errors.add('Invalid credit card type: $ccType');
          }
        }
      }
    }

    // IBAN validation (if provided)
    if (data.containsKey('iban') && data['iban'] != null) {
      final String iban = (data['iban'] as String).replaceAll(' ', '');
      if (iban.isNotEmpty && !_isValidIBAN(iban)) {
        errors.add('Invalid IBAN format');
      }
    }

    // Account number validation
    if (data.containsKey('account_number') && data['account_number'] != null) {
      final String accountNumber = data['account_number'] as String;
      if (accountNumber.length > 255) {
        errors.add('Account number exceeds maximum length of 255 characters');
      }
    }

    // Notes validation
    if (data.containsKey('notes') && data['notes'] != null) {
      final String notes = data['notes'] as String;
      if (notes.length > 65535) {
        errors.add('Notes exceed maximum length of 65535 characters');
      }
    }

    // Active flag validation
    if (data.containsKey('active') && data['active'] != null) {
      if (data['active'] is! bool) {
        errors.add('Active flag must be a boolean value');
      }
    }

    // Include net worth validation
    if (data.containsKey('include_net_worth') &&
        data['include_net_worth'] != null) {
      if (data['include_net_worth'] is! bool) {
        errors.add('Include net worth flag must be a boolean value');
      }
    }

    final bool isValid = errors.isEmpty;

    if (!isValid) {
      _logger.warning('Account validation failed: ${errors.join(', ')}');
    } else {
      _logger.fine('Account validation passed');
    }

    return ValidationResult(isValid: isValid, errors: errors);
  }

  /// Validates account balance update
  ///
  /// Ensures balance changes are valid and within acceptable ranges
  ValidationResult validateBalanceUpdate(
    Map<String, dynamic> data,
    double currentBalance,
  ) {
    _logger.fine('Validating balance update');

    final List<String> errors = <String>[];

    if (!data.containsKey('balance') || data['balance'] == null) {
      errors.add('New balance is required');
    } else {
      final double? newBalance = _parseAmount(data['balance']);
      if (newBalance == null) {
        errors.add('Balance must be a valid number');
      } else if (newBalance.abs() > 999999999.99) {
        errors.add('Balance exceeds maximum allowed value');
      }

      // Check for unrealistic balance changes
      final double difference = ((newBalance ?? 0) - currentBalance).abs();
      if (difference > 1000000) {
        _logger.warning('Large balance change detected: $difference');
        // Don't error, just log warning
      }
    }

    final bool isValid = errors.isEmpty;

    if (!isValid) {
      _logger.warning('Balance update validation failed: ${errors.join(', ')}');
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

    // Common currency codes
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

  bool _isValidIBAN(String iban) {
    // Basic IBAN validation (simplified)
    // Real IBAN validation is complex and country-specific
    if (iban.length < 15 || iban.length > 34) return false;

    // Must start with 2 letters (country code)
    if (!RegExp(r'^[A-Z]{2}').hasMatch(iban)) return false;

    // Followed by 2 digits (check digits)
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}').hasMatch(iban)) return false;

    // Rest should be alphanumeric
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(iban)) return false;

    return true;
  }
}
