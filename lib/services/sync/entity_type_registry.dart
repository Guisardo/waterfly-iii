/// Registry of all supported entity types in Firefly III.
///
/// Provides centralized definitions for:
/// - Entity type names
/// - API endpoints
/// - Display names
/// - Validation
///
/// Eliminates hardcoded entity type strings across services.
class EntityTypeRegistry {
  EntityTypeRegistry._();

  /// All supported entity types.
  static const List<EntityTypeInfo> allTypes = [
    EntityTypeInfo(
      type: 'transactions',
      endpoint: '/api/v1/transactions',
      displayName: 'Transactions',
      pluralName: 'transactions',
    ),
    EntityTypeInfo(
      type: 'accounts',
      endpoint: '/api/v1/accounts',
      displayName: 'Accounts',
      pluralName: 'accounts',
    ),
    EntityTypeInfo(
      type: 'categories',
      endpoint: '/api/v1/categories',
      displayName: 'Categories',
      pluralName: 'categories',
    ),
    EntityTypeInfo(
      type: 'budgets',
      endpoint: '/api/v1/budgets',
      displayName: 'Budgets',
      pluralName: 'budgets',
    ),
    EntityTypeInfo(
      type: 'bills',
      endpoint: '/api/v1/bills',
      displayName: 'Bills',
      pluralName: 'bills',
    ),
    EntityTypeInfo(
      type: 'piggy_banks',
      endpoint: '/api/v1/piggy_banks',
      displayName: 'Piggy Banks',
      pluralName: 'piggy banks',
    ),
  ];

  /// Get entity type info by type name.
  static EntityTypeInfo? getByType(String type) {
    try {
      return allTypes.firstWhere((info) => info.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get entity type info by endpoint.
  static EntityTypeInfo? getByEndpoint(String endpoint) {
    try {
      return allTypes.firstWhere((info) => info.endpoint == endpoint);
    } catch (e) {
      return null;
    }
  }

  /// Check if entity type is valid.
  static bool isValidType(String type) {
    return allTypes.any((info) => info.type == type);
  }

  /// Get all entity type names.
  static List<String> get allTypeNames {
    return allTypes.map((info) => info.type).toList();
  }

  /// Get all endpoints.
  static List<String> get allEndpoints {
    return allTypes.map((info) => info.endpoint).toList();
  }

  /// Get display name for entity type.
  static String getDisplayName(String type) {
    final info = getByType(type);
    return info?.displayName ?? type;
  }

  /// Get plural name for entity type.
  static String getPluralName(String type) {
    final info = getByType(type);
    return info?.pluralName ?? type;
  }

  /// Get endpoint for entity type.
  static String? getEndpoint(String type) {
    final info = getByType(type);
    return info?.endpoint;
  }
}

/// Information about an entity type.
class EntityTypeInfo {
  final String type;
  final String endpoint;
  final String displayName;
  final String pluralName;

  const EntityTypeInfo({
    required this.type,
    required this.endpoint,
    required this.displayName,
    required this.pluralName,
  });

  @override
  String toString() => 'EntityTypeInfo($type, $endpoint)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityTypeInfo &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}
