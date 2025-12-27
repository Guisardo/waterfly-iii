import 'dart:async';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/accounts.dart';
import 'package:waterflyiii/data/local/database/tables/attachments.dart';
import 'package:waterflyiii/data/local/database/tables/bills.dart';
import 'package:waterflyiii/data/local/database/tables/budget_limits.dart';
import 'package:waterflyiii/data/local/database/tables/budgets.dart';
import 'package:waterflyiii/data/local/database/tables/categories.dart';
import 'package:waterflyiii/data/local/database/tables/currencies.dart';
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/local/database/tables/piggy_banks.dart';
import 'package:waterflyiii/data/local/database/tables/sync_conflicts.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/data/local/database/tables/tags.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';

// Unsafe cast helper to bypass type checking for mocks
// Uses a workaround: cast to Object first, then to target type
// This bypasses Dart's runtime type checking for incompatible types
@pragma('vm:unsafe-type-cast')
T unsafeCast<T>(dynamic value) {
  // Use Object as intermediate to bypass type checking
  return (value as Object) as T;
}

// Mock Query for buildQuery
class _MockQuery<T> implements Query<T> {
  final List<T> _data;
  
  _MockQuery(this._data);
  
  @override
  Future<List<T>> findAll() async => _data;
  
  @override
  List<T> findAllSync() => _data;
  
  @override
  Future<T?> findFirst() async => _data.isNotEmpty ? _data.first : null;
  
  @override
  T? findFirstSync() => _data.isNotEmpty ? _data.first : null;
  
  @override
  Future<int> count() async => _data.length;
  
  @override
  int countSync() => _data.length;
  
  @override
  Future<bool> isEmpty() async => _data.isEmpty;
  
  @override
  bool isEmptySync() => _data.isEmpty;
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('_MockQuery: ${invocation.memberName}');
  }
}

// Mock collection for QueryBuilderInternal when collection is null
class _MockCollection<T> implements IsarCollection<T> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('_MockCollection: ${invocation.memberName}');
  }
}

/// Mock query builder for Isar collections
/// Extends QueryBuilder to be compatible with IsarCollection interface
/// Generic over state type S to support both QWhere and QFilterCondition
class MockQueryBuilder<T, S> extends QueryBuilder<T, T, S> {
  final List<T> _data;
  final Map<String, Function(T, dynamic)> _fieldComparators;
  final IsarCollection<T>? _collection;

  MockQueryBuilder(this._data, this._fieldComparators, [IsarCollection<T>? collection])
      : _collection = collection,
        super(
          QueryBuilderInternal<T>(
            collection: collection ?? _MockCollection<T>(),
            whereClauses: const [],
            whereDistinct: false,
            whereSort: Sort.asc,
            filter: const FilterGroup.and([]),
            filterGroupType: FilterGroupType.and,
            filterNot: false,
            distinctByProperties: const [],
            sortByProperties: const [],
            offset: null,
            limit: null,
            propertyName: null,
          ),
        ) {}

  QueryBuilder<T, T, QWhere> where() {
    // Use collection's data if available, otherwise use our _data
    final List<T> dataToUse = _collection is MockIsarCollection<T>
        ? _collection.data
        : _data;
    return MockQueryBuilder<T, QWhere>(dataToUse, _fieldComparators, _collection);
  }

  QueryBuilder<T, T, QFilterCondition> filter() {
    // Use collection's data if available, otherwise use our _data
    final List<T> dataToUse = _collection is MockIsarCollection<T>
        ? _collection.data
        : _data;
    return MockQueryBuilder<T, QFilterCondition>(dataToUse, _fieldComparators, _collection);
  }

  // Field equality methods - dynamically handle any field
  QueryBuilder<T, T, QFilterCondition> _applyFilter(String field, dynamic value) {
    return MockQueryBuilder<T, QFilterCondition>(
      _data.where((item) {
        final comparator = _fieldComparators[field];
        if (comparator != null) {
          return comparator(item, value);
        }
        // Fallback: try to access field via dynamic
        try {
          final dynamic itemDynamic = item as dynamic;
          // Try direct field access
          try {
            final dynamic itemValue = (itemDynamic as dynamic)[field];
            return itemValue == value;
          } catch (e) {
            return false;
          }
        } catch (e) {
          return false;
        }
      }).toList(),
      _fieldComparators,
      _collection,
    );
  }

  // Dynamic method calls for field equality (e.g., transactionIdEqualTo, accountIdEqualTo)
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final String name = invocation.memberName.toString();
    if (name.endsWith('EqualTo')) {
      // Extract field name from method name (e.g., "transactionIdEqualTo" -> "transactionId")
      final fieldName = name.replaceAll('EqualTo', '');
      if (invocation.positionalArguments.isNotEmpty) {
        return _applyFilter(fieldName, invocation.positionalArguments.first);
      }
    }
    return super.noSuchMethod(invocation);
  }

  // Override build to return a MockQuery that uses our data
  // This ensures QueryBuilder.build().findAll() works correctly
  // CRITICAL: Always use collection.data directly, not _data, to ensure we get the live reference
  Query<T> build() {
    // Always use the collection's current data if available (it's a live reference)
    // _data is a reference to the collection's data list, but collection.data is always current
    if (_collection != null && _collection is MockIsarCollection) {
      final MockIsarCollection<T> mockCollection = _collection as MockIsarCollection<T>;
      final List<T> collectionData = mockCollection.data;
      // Return _MockQuery with collection.data directly - this is the live reference
      return _MockQuery<T>(collectionData);
    }
    return _MockQuery<T>(_data);
  }

  // Override findAll and findFirst to use our mock data directly
  // CRITICAL: Use EXACT same pattern as findFirst() which works correctly
  Future<List<T>> findAll() async {
    // Use EXACT same pattern as findFirst() which works - return whole list instead of first element
    List<T> dataToUse = _data;
    if (_collection != null) {
      try {
        final dynamic coll = _collection;
        if (coll is MockIsarCollection) {
          dataToUse = (coll.data as List<T>);
        }
      } catch (e) {
        // Use _data fallback
      }
    }
    // Return the whole list (findFirst() returns dataToUse.isNotEmpty ? dataToUse.first : null)
    return dataToUse;
  }

  Future<T?> findFirst() async {
    List<T> dataToUse = _data;
    if (_collection != null) {
      try {
        final dynamic coll = _collection;
        if (coll is MockIsarCollection) {
          dataToUse = (coll.data as List<T>);
        }
      } catch (e) {
        // Use _data fallback
      }
    }
    return dataToUse.isNotEmpty ? dataToUse.first : null;
  }
  
  List<T> findAllSync() {
    // Use EXACT same pattern as findFirstSync() which works
    // The only difference: return the whole list instead of first element
    List<T> dataToUse = _data;
    if (_collection != null) {
      try {
        final dynamic coll = _collection;
        final dynamic collectionData = (coll as dynamic).data;
        if (collectionData is List) {
          dataToUse = collectionData.cast<T>();
        }
      } catch (e) {
        // Use _data fallback
      }
    }
    // Return the whole list (findFirstSync() returns dataToUse.isNotEmpty ? dataToUse.first : null)
    return dataToUse;
  }
  
  T? findFirstSync() {
    List<T> dataToUse = _data;
    if (_collection != null) {
      try {
        final dynamic coll = _collection;
        final dynamic collectionData = (coll as dynamic).data;
        if (collectionData is List) {
          dataToUse = collectionData.cast<T>();
        }
      } catch (e) {
        // Use _data fallback
      }
    }
    return dataToUse.isNotEmpty ? dataToUse.first : null;
  }
}

/// Mock Isar collection that implements IsarCollection interface
class MockIsarCollection<T> implements IsarCollection<T> {
  // Make _data accessible to MockQueryBuilder (remove private to allow access)
  final List<T> data = [];
  final Map<String, Function(T, dynamic)> _fieldComparators;
  final Isar _isar;

  MockIsarCollection(this._fieldComparators, this._isar);

  @override
  QueryBuilder<T, T, QWhere> where({
    List<WhereClause> whereClauses = const [],
    bool distinct = false,
    Sort sort = Sort.asc,
  }) {
    return MockQueryBuilder<T, QWhere>(data, _fieldComparators, this);
  }

  @override
  QueryBuilder<T, T, QFilterCondition> filter() {
    return MockQueryBuilder<T, QFilterCondition>(data, _fieldComparators, this);
  }

  @override
  Isar get isar => _isar;

  @override
  String get name => T.toString();

  @override
  CollectionSchema<T> get schema => throw UnimplementedError('Mock: schema not needed for tests');

  @override
  Future<Id> put(T object) async {
    // For objects with an id field, update if exists, otherwise add
    try {
      final dynamic obj = object;
      final int? id = obj.id;
      if (id != null && id != 0) {
        final int index = data.indexWhere((item) {
          try {
            return (item as dynamic).id == id;
          } catch (e) {
            return false;
          }
        });
        if (index >= 0) {
          data[index] = object;
          return id;
        }
      }
    } catch (e) {
      // If no id field, just add
    }
    // Generate a new ID if not present
    // Isar.autoIncrement is a special sentinel value (-9223372036854775808)
    // We need to check for this value, not just 0
    final dynamic obj = object;
    final int autoIncrementValue = -9223372036854775808; // Isar.autoIncrement
    if (obj.id == null || obj.id == 0 || obj.id == autoIncrementValue) {
      obj.id = data.length + 1;
    }
    data.add(object);
    return (obj as dynamic).id as Id;
  }

  @override
  Id putSync(T object, {bool saveLinks = true}) {
    try {
      final dynamic obj = object;
      final int? id = obj.id;
      if (id != null && id != 0) {
        final int index = data.indexWhere((item) {
          try {
            return (item as dynamic).id == id;
          } catch (e) {
            return false;
          }
        });
        if (index >= 0) {
          data[index] = object;
          return id;
        }
      }
    } catch (e) {
      // If no id field, just add
    }
    final dynamic obj = object;
    final int autoIncrementValue = -9223372036854775808; // Isar.autoIncrement
    if (obj.id == null || obj.id == 0 || obj.id == autoIncrementValue) {
      obj.id = data.length + 1;
    }
    data.add(object);
    return (obj as dynamic).id as Id;
  }

  @override
  Future<List<Id>> putAll(List<T> objects) async {
    final List<Id> ids = [];
    for (final obj in objects) {
      final Id id = await put(obj);
      ids.add(id);
    }
    return ids;
  }

  @override
  List<Id> putAllSync(List<T> objects, {bool saveLinks = true}) {
    final List<Id> ids = [];
    for (final obj in objects) {
      final Id id = putSync(obj, saveLinks: saveLinks);
      ids.add(id);
    }
    return ids;
  }

  @override
  Future<void> clear() async {
    data.clear();
  }

  @override
  void clearSync() {
    data.clear();
  }

  @override
  Future<bool> delete(Id id) async {
    final int index = data.indexWhere((item) {
      try {
        return (item as dynamic).id == id;
      } catch (e) {
        return false;
      }
    });
    if (index >= 0) {
      data.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  bool deleteSync(Id id) {
    final int index = data.indexWhere((item) {
      try {
        return (item as dynamic).id == id;
      } catch (e) {
        return false;
      }
    });
    if (index >= 0) {
      data.removeAt(index);
      return true;
    }
    return false;
  }

  @override
  Future<int> deleteAll(List<Id> ids) async {
    int count = 0;
    for (final id in ids) {
      if (await delete(id)) {
        count++;
      }
    }
    return count;
  }

  @override
  int deleteAllSync(List<Id> ids) {
    int count = 0;
    for (final id in ids) {
      if (deleteSync(id)) {
        count++;
      }
    }
    return count;
  }

  @override
  Future<T?> get(Id id) async {
    try {
      return data.firstWhere((item) {
        try {
          return (item as dynamic).id == id;
        } catch (e) {
          return false;
        }
      });
    } catch (e) {
      return null;
    }
  }

  @override
  T? getSync(Id id) {
    try {
      return data.firstWhere((item) {
        try {
          return (item as dynamic).id == id;
        } catch (e) {
          return false;
        }
      });
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<T>> getAll(List<Id> ids) async {
    return data.where((item) {
      try {
        return ids.contains((item as dynamic).id);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  List<T> getAllSync(List<Id> ids) {
    return data.where((item) {
      try {
        return ids.contains((item as dynamic).id);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Future<int> count() async => data.length;

  @override
  int countSync() => data.length;

  @override
  Future<int> getSize({bool includeIndexes = false, bool includeLinks = false}) async => data.length;

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) => data.length;

  // Stub implementations for unused methods
  @override
  Query<R> buildQuery<R>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    // Return a mock Query that uses our data directly - this is the live reference
    return _MockQuery<R>(data.cast<R>());
  }

  @override
  Future<bool> deleteByIndex(String indexName, IndexKey key) async {
    throw UnimplementedError('Mock: deleteByIndex not needed for tests');
  }

  @override
  bool deleteByIndexSync(String indexName, IndexKey key) {
    throw UnimplementedError('Mock: deleteByIndexSync not needed for tests');
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) async {
    throw UnimplementedError('Mock: deleteAllByIndex not needed for tests');
  }

  @override
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys) {
    throw UnimplementedError('Mock: deleteAllByIndexSync not needed for tests');
  }

  @override
  Future<T?> getByIndex(String indexName, IndexKey key) async {
    throw UnimplementedError('Mock: getByIndex not needed for tests');
  }

  @override
  T? getByIndexSync(String indexName, IndexKey key) {
    throw UnimplementedError('Mock: getByIndexSync not needed for tests');
  }

  @override
  Future<List<T>> getAllByIndex(String indexName, List<IndexKey> keys) async {
    throw UnimplementedError('Mock: getAllByIndex not needed for tests');
  }

  @override
  List<T> getAllByIndexSync(String indexName, List<IndexKey> keys) {
    throw UnimplementedError('Mock: getAllByIndexSync not needed for tests');
  }

  @override
  Future<Id> putByIndex(String indexName, T object) async {
    return await put(object);
  }

  @override
  Id putByIndexSync(String indexName, T object, {bool saveLinks = true}) {
    return putSync(object, saveLinks: saveLinks);
  }

  @override
  Future<List<Id>> putAllByIndex(String indexName, List<T> objects) async {
    return await putAll(objects);
  }

  @override
  List<Id> putAllByIndexSync(String indexName, List<T> objects, {bool saveLinks = true}) {
    return putAllSync(objects, saveLinks: saveLinks);
  }

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) async {
    throw UnimplementedError('Mock: importJson not needed for tests');
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json) {
    throw UnimplementedError('Mock: importJsonSync not needed for tests');
  }

  @override
  Future<void> importJsonRaw(Uint8List json) async {
    throw UnimplementedError('Mock: importJsonRaw not needed for tests');
  }

  @override
  void importJsonRawSync(Uint8List json) {
    throw UnimplementedError('Mock: importJsonRawSync not needed for tests');
  }

  @override
  Stream<T?> watchObject(Id id, {bool fireImmediately = false}) {
    throw UnimplementedError('Mock: watchObject not needed for tests');
  }

  @override
  Stream<List<T>> watchLazy({bool fireImmediately = false}) {
    throw UnimplementedError('Mock: watchLazy not needed for tests');
  }

  @override
  Stream<T?> watchObjectLazy(Id id, {bool fireImmediately = false}) {
    throw UnimplementedError('Mock: watchObjectLazy not needed for tests');
  }

  @override
  Future<bool> verify([List<T>? repair]) async {
    return true;
  }

  @override
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) async {
    // No-op for mock
  }
}

// Temporary Isar instance for initialization
class _TempIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('_TempIsar: ${invocation.memberName}');
  }
}

/// Mock Isar implementation for unit tests
class MockIsar implements Isar {
  final MockIsarCollection<Transactions> transactions;
  final MockIsarCollection<Accounts> accounts;
  final MockIsarCollection<Categories> categories;
  final MockIsarCollection<Tags> tags;
  final MockIsarCollection<Bills> bills;
  final MockIsarCollection<Budgets> budgets;
  final MockIsarCollection<BudgetLimits> budgetLimits;
  final MockIsarCollection<Currencies> currencies;
  final MockIsarCollection<PiggyBanks> piggyBanks;
  final MockIsarCollection<Attachments> attachments;
  final MockIsarCollection<Insights> insights;
  final MockIsarCollection<SyncMetadata> syncMetadatas;
  final MockIsarCollection<PendingChanges> pendingChanges;
  final MockIsarCollection<SyncConflicts> syncConflicts;

  MockIsar()
      : transactions = MockIsarCollection<Transactions>({
          'transactionId': (t, v) => t.transactionId == v,
        }, _TempIsar()),
        accounts = MockIsarCollection<Accounts>({
          'accountId': (t, v) => t.accountId == v,
        }, _TempIsar()),
        categories = MockIsarCollection<Categories>({
          'categoryId': (t, v) => t.categoryId == v,
        }, _TempIsar()),
        tags = MockIsarCollection<Tags>({
          'tagId': (t, v) => t.tagId == v,
        }, _TempIsar()),
        bills = MockIsarCollection<Bills>({
          'billId': (t, v) => t.billId == v,
        }, _TempIsar()),
        budgets = MockIsarCollection<Budgets>({
          'budgetId': (t, v) => t.budgetId == v,
        }, _TempIsar()),
        budgetLimits = MockIsarCollection<BudgetLimits>({
          'budgetLimitId': (t, v) => t.budgetLimitId == v,
        }, _TempIsar()),
        currencies = MockIsarCollection<Currencies>({
          'currencyId': (t, v) => t.currencyId == v,
        }, _TempIsar()),
        piggyBanks = MockIsarCollection<PiggyBanks>({
          'piggyBankId': (t, v) => t.piggyBankId == v,
        }, _TempIsar()),
        attachments = MockIsarCollection<Attachments>({
          'attachmentId': (t, v) => t.attachmentId == v,
        }, _TempIsar()),
        insights = MockIsarCollection<Insights>({
          'insightType': (t, v) => t.insightType == v,
          'insightSubtype': (t, v) => t.insightSubtype == v,
          'startDate': (t, v) => t.startDate == v,
          'endDate': (t, v) => t.endDate == v,
          'stale': (t, v) => t.stale == v,
        }, _TempIsar()),
        syncMetadatas = MockIsarCollection<SyncMetadata>({
          'entityType': (t, v) => t.entityType == v,
        }, _TempIsar()),
        pendingChanges = MockIsarCollection<PendingChanges>({
          'entityType': (t, v) => t.entityType == v,
          'entityId': (t, v) => t.entityId == v,
          'operation': (t, v) => t.operation == v,
        }, _TempIsar()),
        syncConflicts = MockIsarCollection<SyncConflicts>({
          'entityType': (t, v) => t.entityType == v,
          'entityId': (t, v) => t.entityId == v,
        }, _TempIsar());

  // Implement all required Isar interface methods
  @override
  void attachCollections(Map<Type, IsarCollection<dynamic>> collections) {
    // No-op for mock
  }

  @override
  IsarCollection<T> collection<T>() {
    // Return the appropriate collection based on type
    if (T == Transactions) return transactions as IsarCollection<T>;
    if (T == Accounts) return accounts as IsarCollection<T>;
    if (T == Categories) return categories as IsarCollection<T>;
    if (T == Tags) return tags as IsarCollection<T>;
    if (T == Bills) return bills as IsarCollection<T>;
    if (T == Budgets) return budgets as IsarCollection<T>;
    if (T == BudgetLimits) return budgetLimits as IsarCollection<T>;
    if (T == Currencies) return currencies as IsarCollection<T>;
    if (T == PiggyBanks) return piggyBanks as IsarCollection<T>;
    if (T == Attachments) return attachments as IsarCollection<T>;
    if (T == Insights) return insights as IsarCollection<T>;
    if (T == SyncMetadata) return syncMetadatas as IsarCollection<T>;
    if (T == PendingChanges) return pendingChanges as IsarCollection<T>;
    if (T == SyncConflicts) return syncConflicts as IsarCollection<T>;
    throw UnimplementedError('Mock: Collection for type $T not found');
  }

  @override
  Future<void> clear() async {
    // Clear all collections
    await transactions.clear();
    await accounts.clear();
    await categories.clear();
    await tags.clear();
    await bills.clear();
    await budgets.clear();
    await budgetLimits.clear();
    await currencies.clear();
    await piggyBanks.clear();
    await attachments.clear();
    await insights.clear();
    await syncMetadatas.clear();
    await pendingChanges.clear();
    await syncConflicts.clear();
  }

  @override
  void clearSync() {
    transactions.clearSync();
    accounts.clearSync();
    categories.clearSync();
    tags.clearSync();
    bills.clearSync();
    budgets.clearSync();
    budgetLimits.clearSync();
    currencies.clearSync();
    piggyBanks.clearSync();
    attachments.clearSync();
    insights.clearSync();
    syncMetadatas.clearSync();
    pendingChanges.clearSync();
    syncConflicts.clearSync();
  }

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    return true;
  }

  @override
  Future<void> copyToFile(String targetPath) async {
    throw UnimplementedError('Mock: copyToFile not needed for tests');
  }

  @override
  String? get directory => null;

  @override
  IsarCollection<dynamic>? getCollectionByNameInternal(String name) {
    throw UnimplementedError('Mock: getCollectionByNameInternal not needed for tests');
  }

  @override
  Future<int> getSize({bool includeIndexes = false, bool includeLinks = false}) async {
    return 0;
  }

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) {
    return 0;
  }

  @override
  bool get isOpen => true;

  @override
  String get name => 'mock';

  @override
  String? get path => null;

  @override
  void requireOpen() {
    // Always open in mock
  }

  @override
  Future<T> txn<T>(Future<T> Function() callback) async {
    return await callback();
  }

  @override
  T txnSync<T>(T Function() callback) {
    return callback();
  }

  @override
  Future<void> verify() async {
    // No-op
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) async {
    return await callback();
  }

  @override
  T writeTxnSync<T>(T Function() callback, {bool silent = false}) {
    return callback();
  }

  Future<T> readTxn<T>(Future<T> Function() callback) async {
    return await callback();
  }
}

