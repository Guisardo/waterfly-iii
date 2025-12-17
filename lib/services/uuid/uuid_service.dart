import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// Service for generating unique identifiers for offline-created entities.
///
/// This service provides methods to generate UUIDs with entity-specific prefixes
/// to help identify the type and origin of entities. All UUIDs are version 4
/// (random) to ensure uniqueness across devices.
///
/// Features:
/// - Entity-specific UUID generation with prefixes
/// - Collision-free UUID generation
/// - Comprehensive logging
/// - Validation methods
///
/// Example:
/// ```dart
/// final service = UuidService();
/// final transactionId = service.generateTransactionId();
/// final accountId = service.generateAccountId();
///
/// // Check if ID is offline-generated
/// if (service.isOfflineId(transactionId)) {
///   print('This transaction was created offline');
/// }
/// ```
class UuidService {
  static final UuidService _instance = UuidService._internal();

  /// Returns the singleton instance of [UuidService].
  factory UuidService() => _instance;

  UuidService._internal();

  final Logger _logger = Logger('UuidService');
  final Uuid _uuid = const Uuid();

  // Entity type prefixes for offline-generated IDs
  static const String _transactionPrefix = 'offline_txn_';
  static const String _accountPrefix = 'offline_acc_';
  static const String _categoryPrefix = 'offline_cat_';
  static const String _budgetPrefix = 'offline_bdg_';
  static const String _billPrefix = 'offline_bil_';
  static const String _piggyBankPrefix = 'offline_pig_';
  static const String _tagPrefix = 'offline_tag_';
  static const String _attachmentPrefix = 'offline_att_';
  static const String _operationPrefix = 'offline_op_';

  /// Generates a unique ID for a transaction.
  ///
  /// Returns a UUID v4 with the prefix 'offline_txn_'.
  ///
  /// Example: 'offline_txn_550e8400-e29b-41d4-a716-446655440000'
  String generateTransactionId() {
    final String id = '$_transactionPrefix${_uuid.v4()}';
    _logger.fine('Generated transaction ID: $id');
    return id;
  }

  /// Generates a unique ID for an account.
  ///
  /// Returns a UUID v4 with the prefix 'offline_acc_'.
  ///
  /// Example: 'offline_acc_550e8400-e29b-41d4-a716-446655440000'
  String generateAccountId() {
    final String id = '$_accountPrefix${_uuid.v4()}';
    _logger.fine('Generated account ID: $id');
    return id;
  }

  /// Generates a unique ID for a category.
  ///
  /// Returns a UUID v4 with the prefix 'offline_cat_'.
  ///
  /// Example: 'offline_cat_550e8400-e29b-41d4-a716-446655440000'
  String generateCategoryId() {
    final String id = '$_categoryPrefix${_uuid.v4()}';
    _logger.fine('Generated category ID: $id');
    return id;
  }

  /// Generates a unique ID for a budget.
  ///
  /// Returns a UUID v4 with the prefix 'offline_bdg_'.
  ///
  /// Example: 'offline_bdg_550e8400-e29b-41d4-a716-446655440000'
  String generateBudgetId() {
    final String id = '$_budgetPrefix${_uuid.v4()}';
    _logger.fine('Generated budget ID: $id');
    return id;
  }

  /// Generates a unique ID for a bill.
  ///
  /// Returns a UUID v4 with the prefix 'offline_bil_'.
  ///
  /// Example: 'offline_bil_550e8400-e29b-41d4-a716-446655440000'
  String generateBillId() {
    final String id = '$_billPrefix${_uuid.v4()}';
    _logger.fine('Generated bill ID: $id');
    return id;
  }

  /// Generates a unique ID for a piggy bank.
  ///
  /// Returns a UUID v4 with the prefix 'offline_pig_'.
  ///
  /// Example: 'offline_pig_550e8400-e29b-41d4-a716-446655440000'
  String generatePiggyBankId() {
    final String id = '$_piggyBankPrefix${_uuid.v4()}';
    _logger.fine('Generated piggy bank ID: $id');
    return id;
  }

  /// Generates a unique ID for a tag.
  ///
  /// Returns a UUID v4 with the prefix 'offline_tag_'.
  ///
  /// Example: 'offline_tag_550e8400-e29b-41d4-a716-446655440000'
  String generateTagId() {
    final String id = '$_tagPrefix${_uuid.v4()}';
    _logger.fine('Generated tag ID: $id');
    return id;
  }

  /// Generates a unique ID for an attachment.
  ///
  /// Returns a UUID v4 with the prefix 'offline_att_'.
  ///
  /// Example: 'offline_att_550e8400-e29b-41d4-a716-446655440000'
  String generateAttachmentId() {
    final String id = '$_attachmentPrefix${_uuid.v4()}';
    _logger.fine('Generated attachment ID: $id');
    return id;
  }

  /// Generates a unique ID for a sync operation.
  ///
  /// Returns a UUID v4 with the prefix 'offline_op_'.
  ///
  /// Example: 'offline_op_550e8400-e29b-41d4-a716-446655440000'
  String generateOperationId() {
    final String id = '$_operationPrefix${_uuid.v4()}';
    _logger.fine('Generated operation ID: $id');
    return id;
  }

  /// Generates a plain UUID v4 without any prefix.
  ///
  /// Use this for general-purpose UUID generation.
  ///
  /// Example: '550e8400-e29b-41d4-a716-446655440000'
  String generateUuid() {
    final String id = _uuid.v4();
    _logger.fine('Generated plain UUID: $id');
    return id;
  }

  /// Checks if an ID was generated offline (has an offline prefix).
  ///
  /// Returns `true` if the ID starts with any offline prefix.
  bool isOfflineId(String id) {
    return id.startsWith('offline_');
  }

  /// Checks if an ID is a transaction ID.
  bool isTransactionId(String id) {
    return id.startsWith(_transactionPrefix);
  }

  /// Checks if an ID is an account ID.
  bool isAccountId(String id) {
    return id.startsWith(_accountPrefix);
  }

  /// Checks if an ID is a category ID.
  bool isCategoryId(String id) {
    return id.startsWith(_categoryPrefix);
  }

  /// Checks if an ID is a budget ID.
  bool isBudgetId(String id) {
    return id.startsWith(_budgetPrefix);
  }

  /// Checks if an ID is a bill ID.
  bool isBillId(String id) {
    return id.startsWith(_billPrefix);
  }

  /// Checks if an ID is a piggy bank ID.
  bool isPiggyBankId(String id) {
    return id.startsWith(_piggyBankPrefix);
  }

  /// Checks if an ID is a tag ID.
  bool isTagId(String id) {
    return id.startsWith(_tagPrefix);
  }

  /// Checks if an ID is an attachment ID.
  bool isAttachmentId(String id) {
    return id.startsWith(_attachmentPrefix);
  }

  /// Checks if an ID is an operation ID.
  bool isOperationId(String id) {
    return id.startsWith(_operationPrefix);
  }

  /// Extracts the UUID part from an offline ID (removes the prefix).
  ///
  /// Returns the UUID without the prefix, or the original ID if it has no prefix.
  ///
  /// Example:
  /// ```dart
  /// final id = 'offline_txn_550e8400-e29b-41d4-a716-446655440000';
  /// final uuid = service.extractUuid(id);
  /// // uuid = '550e8400-e29b-41d4-a716-446655440000'
  /// ```
  String extractUuid(String id) {
    if (!isOfflineId(id)) {
      return id;
    }

    final List<String> prefixes = <String>[
      _transactionPrefix,
      _accountPrefix,
      _categoryPrefix,
      _budgetPrefix,
      _billPrefix,
      _piggyBankPrefix,
      _tagPrefix,
      _attachmentPrefix,
      _operationPrefix,
    ];

    for (final String prefix in prefixes) {
      if (id.startsWith(prefix)) {
        return id.substring(prefix.length);
      }
    }

    return id;
  }

  /// Validates that a string is a valid UUID format.
  ///
  /// Returns `true` if the string matches UUID v4 format.
  bool isValidUuid(String id) {
    // Remove prefix if present
    final String uuid = extractUuid(id);

    // UUID v4 regex pattern
    final RegExp uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    return uuidPattern.hasMatch(uuid);
  }

  /// Gets the entity type from an offline ID.
  ///
  /// Returns the entity type ('transaction', 'account', etc.) or null
  /// if the ID is not an offline ID or has an unknown prefix.
  String? getEntityType(String id) {
    if (isTransactionId(id)) return 'transaction';
    if (isAccountId(id)) return 'account';
    if (isCategoryId(id)) return 'category';
    if (isBudgetId(id)) return 'budget';
    if (isBillId(id)) return 'bill';
    if (isPiggyBankId(id)) return 'piggy_bank';
    if (isTagId(id)) return 'tag';
    if (isAttachmentId(id)) return 'attachment';
    if (isOperationId(id)) return 'operation';
    return null;
  }
}
