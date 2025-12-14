import 'package:logging/logging.dart';

import 'transaction_validator.dart';

/// Validates category data before storage or synchronization.
///
/// Ensures category names are unique and within valid constraints.
class CategoryValidator {
  final Logger _logger = Logger('CategoryValidator');

  /// Validates category data
  Future<ValidationResult> validate(
    Map<String, dynamic> data, {
    Future<bool> Function(String)? nameExists,
  }) async {
    _logger.fine('Validating category data');

    final errors = <String>[];

    // Required fields
    if (!data.containsKey('name') ||
        data['name'] == null ||
        (data['name'] as String).trim().isEmpty) {
      errors.add('Category name is required');
    } else {
      final name = (data['name'] as String).trim();

      if (name.length > 255) {
        errors.add('Category name exceeds maximum length of 255 characters');
      }

      // Check for duplicate names
      if (nameExists != null && await nameExists(name)) {
        errors.add('A category with name "$name" already exists');
      }
    }

    // Notes validation
    if (data.containsKey('notes') && data['notes'] != null) {
      final notes = data['notes'] as String;
      if (notes.length > 65535) {
        errors.add('Notes exceed maximum length');
      }
    }

    final isValid = errors.isEmpty;
    if (!isValid) {
      _logger.warning('Category validation failed: ${errors.join(', ')}');
    }

    return ValidationResult(isValid: isValid, errors: errors);
  }
}
