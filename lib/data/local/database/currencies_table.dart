import 'package:drift/drift.dart';

/// Currencies table for storing Firefly III currencies locally.
///
/// Stores all configured currencies from Firefly III including their
/// codes, symbols, decimal places, and enabled status.
///
/// Currency data is relatively static and rarely changes, making it ideal
/// for long-term caching (TTL: 24 hours as per CacheTtlConfig).
///
/// Primary use cases:
/// - Currency selection dropdowns in transaction forms
/// - Formatting amounts with correct symbols and decimal places
/// - Multi-currency account displays
/// - Offline currency lookups
@DataClassName('CurrencyEntity')
class Currencies extends Table {
  /// Unique identifier (UUID) for the currency.
  ///
  /// Uses server ID directly since currencies are read-only and
  /// cannot be created offline.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API.
  ///
  /// For currencies, this is typically the same as the local ID
  /// since currencies cannot be created offline.
  TextColumn get serverId => text().nullable()();

  /// ISO 4217 currency code (e.g., 'USD', 'EUR', 'GBP').
  ///
  /// This is the primary identifier used by Firefly III for
  /// currency references in transactions and accounts.
  TextColumn get code => text()();

  /// Human-readable currency name (e.g., 'US Dollar', 'Euro').
  TextColumn get name => text()();

  /// Currency symbol (e.g., '$', '€', '£').
  ///
  /// Used for display formatting in the UI.
  TextColumn get symbol => text()();

  /// Number of decimal places for this currency.
  ///
  /// Most currencies use 2 (e.g., USD, EUR), but some use 0 (e.g., JPY)
  /// or 3 (e.g., KWD). Defaults to 2 if not specified.
  IntColumn get decimalPlaces => integer().withDefault(const Constant(2))();

  /// Whether this currency is enabled in the Firefly III instance.
  ///
  /// Disabled currencies are typically hidden from dropdowns but
  /// may still appear in historical transactions.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Whether this is the default currency for the Firefly III instance.
  ///
  /// The default currency is used for new transactions and accounts
  /// when no specific currency is selected.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Timestamp when the currency was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the currency was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Server's last updated timestamp for incremental sync change detection.
  ///
  /// Used during incremental sync to determine if the local entity
  /// needs to be updated by comparing with the server's timestamp.
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the currency has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{code}, // Currency codes must be unique
        <Column<Object>>{serverId},
      ];
}

