import 'package:logging/logging.dart';

import 'transaction_validator.dart';

/// Validates budget data before storage or synchronization.
class BudgetValidator {
  final Logger _logger = Logger('BudgetValidator');

  /// Validates budget data
  Future<ValidationResult> validate(Map<String, dynamic> data) async {
    _logger.fine('Validating budget data');

    final errors = <String>[];

    // Required fields
    if (!data.containsKey('name') ||
        data['name'] == null ||
        (data['name'] as String).trim().isEmpty) {
      errors.add('Budget name is required');
    } else {
      final name = (data['name'] as String).trim();
      if (name.length > 255) {
        errors.add('Budget name exceeds maximum length of 255 characters');
      }
    }

    // Amount validation
    if (data.containsKey('amount') && data['amount'] != null) {
      final amount = _parseAmount(data['amount']);
      if (amount == null) {
        errors.add('Budget amount must be a valid number');
      } else if (amount < 0) {
        errors.add('Budget amount cannot be negative');
      } else if (amount > 999999999.99) {
        errors.add('Budget amount exceeds maximum allowed value');
      }
    }

    // Period validation
    if (data.containsKey('period') && data['period'] != null) {
      final period = data['period'] as String;
      const validPeriods = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];
      if (!validPeriods.contains(period.toLowerCase())) {
        errors.add('Invalid budget period: $period');
      }
    }

    // Date range validation
    if (data.containsKey('start_date') && data['start_date'] != null) {
      final startDate = _parseDate(data['start_date']);
      if (startDate == null) {
        errors.add('Invalid start date format');
      }

      if (data.containsKey('end_date') && data['end_date'] != null) {
        final endDate = _parseDate(data['end_date']);
        if (endDate == null) {
          errors.add('Invalid end date format');
        } else if (startDate != null && endDate.isBefore(startDate)) {
          errors.add('End date must be after start date');
        }
      }
    }

    final isValid = errors.isEmpty;
    if (!isValid) {
      _logger.warning('Budget validation failed: ${errors.join(', ')}');
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
