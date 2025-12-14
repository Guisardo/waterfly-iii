import 'package:logging/logging.dart';

import 'transaction_validator.dart';

/// Validates bill data before storage or synchronization.
class BillValidator {
  final Logger _logger = Logger('BillValidator');

  /// Validates bill data
  Future<ValidationResult> validate(Map<String, dynamic> data) async {
    _logger.fine('Validating bill data');

    final errors = <String>[];

    // Required fields
    if (!data.containsKey('name') ||
        data['name'] == null ||
        (data['name'] as String).trim().isEmpty) {
      errors.add('Bill name is required');
    } else {
      final name = (data['name'] as String).trim();
      if (name.length > 255) {
        errors.add('Bill name exceeds maximum length of 255 characters');
      }
    }

    // Amount validation
    if (!data.containsKey('amount_min') || data['amount_min'] == null) {
      errors.add('Minimum amount is required');
    } else {
      final amountMin = _parseAmount(data['amount_min']);
      if (amountMin == null) {
        errors.add('Minimum amount must be a valid number');
      } else if (amountMin < 0) {
        errors.add('Minimum amount cannot be negative');
      }

      if (data.containsKey('amount_max') && data['amount_max'] != null) {
        final amountMax = _parseAmount(data['amount_max']);
        if (amountMax == null) {
          errors.add('Maximum amount must be a valid number');
        } else if (amountMin != null && amountMax < amountMin) {
          errors.add('Maximum amount must be greater than or equal to minimum amount');
        }
      }
    }

    // Date validation
    if (!data.containsKey('date') || data['date'] == null) {
      errors.add('Bill date is required');
    } else {
      final date = _parseDate(data['date']);
      if (date == null) {
        errors.add('Invalid date format');
      }
    }

    // Repeat frequency validation
    if (data.containsKey('repeat_freq') && data['repeat_freq'] != null) {
      final repeatFreq = data['repeat_freq'] as String;
      const validFrequencies = [
        'daily', 'weekly', 'monthly', 'quarterly', 'half-year', 'yearly'
      ];
      if (!validFrequencies.contains(repeatFreq.toLowerCase())) {
        errors.add('Invalid repeat frequency: $repeatFreq');
      }
    }

    // Skip validation
    if (data.containsKey('skip') && data['skip'] != null) {
      final skip = data['skip'];
      if (skip is! int || skip < 0) {
        errors.add('Skip must be a non-negative integer');
      }
    }

    // Currency validation
    if (data.containsKey('currency_code') && data['currency_code'] != null) {
      final currencyCode = data['currency_code'] as String;
      if (currencyCode.length != 3 || currencyCode != currencyCode.toUpperCase()) {
        errors.add('Invalid currency code format');
      }
    }

    final isValid = errors.isEmpty;
    if (!isValid) {
      _logger.warning('Bill validation failed: ${errors.join(', ')}');
    }

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
