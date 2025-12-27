import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/accounts.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart' as enums;
import 'package:waterflyiii/data/repositories/currency_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart'
    show
        AccountRead,
        AutocompleteAccount,
        CurrencyRead;

class AccountRepository {
  final Isar isar;

  AccountRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<AccountRead>> getAll() async {
    final List<Accounts> rows = await isar.accounts.where().findAll();
    rows.sort((a, b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((row) {
      return AccountRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<AccountRead?> getById(String id) async {
    final Accounts? row = await isar.accounts
        .filter()
        .accountIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    return AccountRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<List<AccountRead>> search(String query) async {
    final List<AccountRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((account) {
      // Search in account name directly (most common case)
      if (account.attributes.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(account.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<AccountRead>> getByDateRange(DateTime start, DateTime end) async {
    // Accounts don't have date ranges, return all
    return getAll();
  }

  Future<List<AccountRead>> getByType(
    enums.AccountTypeFilter? type, {
    int? page,
    int? limit,
  }) async {
    final List<AccountRead> all = await getAll();
    List<AccountRead> filtered = all;

    // Filter by type if provided
    if (type != null) {
      filtered = all.where((account) {
        final enums.ShortAccountTypeProperty? accountType = account.attributes.type;
        switch (type) {
          case enums.AccountTypeFilter.assetAccount:
            return accountType == enums.ShortAccountTypeProperty.asset;
          case enums.AccountTypeFilter.expenseAccount:
            return accountType == enums.ShortAccountTypeProperty.expense;
          case enums.AccountTypeFilter.revenueAccount:
            return accountType == enums.ShortAccountTypeProperty.revenue;
          case enums.AccountTypeFilter.liabilities:
          case enums.AccountTypeFilter.liability:
            return accountType == enums.ShortAccountTypeProperty.liability ||
                accountType == enums.ShortAccountTypeProperty.liabilities;
          case enums.AccountTypeFilter.loan:
          case enums.AccountTypeFilter.debt:
          case enums.AccountTypeFilter.mortgage:
            return accountType == enums.ShortAccountTypeProperty.liability ||
                accountType == enums.ShortAccountTypeProperty.liabilities;
          case enums.AccountTypeFilter.asset:
            return accountType == enums.ShortAccountTypeProperty.asset;
          case enums.AccountTypeFilter.expense:
            return accountType == enums.ShortAccountTypeProperty.expense;
          case enums.AccountTypeFilter.revenue:
            return accountType == enums.ShortAccountTypeProperty.revenue;
          case enums.AccountTypeFilter.all:
          default:
            return true;
        }
      }).toList();
    }

    // Apply pagination
    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= filtered.length) {
        return <AccountRead>[];
      }
      return filtered.sublist(
        startIndex,
        endIndex > filtered.length ? filtered.length : endIndex,
      );
    }

    return filtered;
  }

  Future<List<AccountRead>> searchByType(
    String query,
    enums.AccountTypeFilter? type, {
    int? page,
    int? limit,
  }) async {
    final List<AccountRead> filtered = await getByType(type);
    final String queryLower = query.toLowerCase();
    final List<AccountRead> results = filtered.where((account) {
      final String json = jsonEncode(account.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();

    // Apply pagination
    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= results.length) {
        return <AccountRead>[];
      }
      return results.sublist(
        startIndex,
        endIndex > results.length ? results.length : endIndex,
      );
    }

    return results;
  }

  Future<List<AutocompleteAccount>> autocomplete({
    String? query,
    List<enums.AccountTypeFilter>? types,
  }) async {
    final List<AccountRead> accounts = await getByType(
      types?.isNotEmpty == true ? types!.first : null,
    );

    // Filter by query if provided
    List<AccountRead> filtered = accounts;
    if (query != null && query.isNotEmpty) {
      final String queryLower = query.toLowerCase();
      filtered = accounts.where((account) {
        return account.attributes.name.toLowerCase().contains(queryLower);
      }).toList();
    }

    // Filter by types if provided
    if (types != null && types.isNotEmpty) {
      filtered = filtered.where((account) {
        final enums.ShortAccountTypeProperty? accountType = account.attributes.type;
        return types.any((type) {
          switch (type) {
            case enums.AccountTypeFilter.assetAccount:
              return accountType == enums.ShortAccountTypeProperty.asset;
            case enums.AccountTypeFilter.expenseAccount:
              return accountType == enums.ShortAccountTypeProperty.expense;
            case enums.AccountTypeFilter.revenueAccount:
              return accountType == enums.ShortAccountTypeProperty.revenue;
            case enums.AccountTypeFilter.liabilities:
            case enums.AccountTypeFilter.liability:
              return accountType == enums.ShortAccountTypeProperty.liability ||
                  accountType == enums.ShortAccountTypeProperty.liabilities;
            case enums.AccountTypeFilter.loan:
            case enums.AccountTypeFilter.debt:
            case enums.AccountTypeFilter.mortgage:
              return accountType == enums.ShortAccountTypeProperty.liability ||
                  accountType == enums.ShortAccountTypeProperty.liabilities;
            case enums.AccountTypeFilter.asset:
              return accountType == enums.ShortAccountTypeProperty.asset;
            case enums.AccountTypeFilter.expense:
              return accountType == enums.ShortAccountTypeProperty.expense;
            case enums.AccountTypeFilter.revenue:
              return accountType == enums.ShortAccountTypeProperty.revenue;
            case enums.AccountTypeFilter.all:
            default:
              return true;
          }
        });
      }).toList();
    }

    // Convert to AutocompleteAccount format
    // Get currency repository for currency names
    final CurrencyRepository currencyRepo = CurrencyRepository(isar);
    final List<CurrencyRead> currencies = await currencyRepo.getAll();
    final Map<String, CurrencyRead> currencyMap = {
      for (final CurrencyRead currency in currencies) currency.id: currency,
    };

    return filtered.map((account) {
      final CurrencyRead? currency = account.attributes.currencyId != null
          ? currencyMap[account.attributes.currencyId]
          : null;
      final String nameWithBalance = account.attributes.currentBalance != null
          ? '${account.attributes.name} (${account.attributes.currentBalance})'
          : account.attributes.name;

      return AutocompleteAccount(
        id: account.id,
        name: account.attributes.name,
        nameWithBalance: nameWithBalance,
        active: account.attributes.active,
        type: account.attributes.type.toString(),
        currencyId: account.attributes.currencyId ?? '',
        currencyName: currency?.attributes.name ?? '',
        currencyCode: account.attributes.currencyCode ?? '',
        currencySymbol: account.attributes.currencySymbol ?? '',
        currencyDecimalPlaces: account.attributes.currencyDecimalPlaces ?? 2,
        accountCurrencyId: account.attributes.currencyId,
        accountCurrencyName: currency?.attributes.name,
        accountCurrencyCode: account.attributes.currencyCode,
        accountCurrencySymbol: account.attributes.currencySymbol,
        accountCurrencyDecimalPlaces: account.attributes.currencyDecimalPlaces,
      );
    }).toList();
  }

  Future<void> create(AccountRead account) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = account.attributes.updatedAt;

    final Accounts row = Accounts()
      ..accountId = account.id
      ..data = jsonEncode(account.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.accounts.put(row);
    });

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'accounts'
      ..entityId = null
      ..operation = 'CREATE'
      ..data = jsonEncode(account.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(AccountRead account) async {
    final DateTime now = _getNow();

    final Accounts? existing = await isar.accounts
        .filter()
        .accountIdEqualTo(account.id)
        .findFirst();

    if (existing != null) {
      existing
        ..data = jsonEncode(account.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.accounts.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'accounts'
      ..entityId = account.id
      ..operation = 'UPDATE'
      ..data = jsonEncode(account.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final Accounts? existing = await isar.accounts
        .filter()
        .accountIdEqualTo(id)
        .findFirst();

    if (existing != null) {
      existing..synced = false;

      await isar.writeTxn(() async {
        await isar.accounts.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'accounts'
      ..entityId = id
      ..operation = 'DELETE'
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> upsertFromSync(AccountRead account) async {
    final DateTime? updatedAt = account.attributes.updatedAt;
    final DateTime now = _getNow();

    final Accounts row = Accounts()
      ..accountId = account.id
      ..data = jsonEncode(account.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = true;

    await isar.writeTxn(() async {
      await isar.accounts.put(row);
    });
  }
}
