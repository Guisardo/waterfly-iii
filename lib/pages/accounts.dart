import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/animations.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/pages/home/accounts/row.dart';
import 'package:waterflyiii/pages/home/accounts/search.dart';
import 'package:waterflyiii/pages/navigation.dart';
import 'package:waterflyiii/widgets/entity_sync_button.dart';

final Logger log = Logger("Pages.Accounts");

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Logger log = Logger("Pages.Accounts.Page");

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: 4);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavPageElements>().appBarBottom = TabBar(
        isScrollable: true,
        controller: _tabController,
        tabAlignment: TabAlignment.start,
        tabs: <Tab>[
          Tab(text: S.of(context).accountsLabelAsset),
          Tab(text: S.of(context).accountsLabelExpense),
          Tab(text: S.of(context).accountsLabelRevenue),
          Tab(text: S.of(context).accountsLabelLiabilities),
        ],
      );

      context.read<NavPageElements>().appBarActions = <Widget>[
        const EntitySyncButton(
          entityType: SyncableEntityType.account,
          // Note: User should pull-to-refresh after sync completes
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: MaterialLocalizations.of(context).searchFieldLabel,
          onPressed: () {
            log.finest(() => "pressed search button");
            Navigator.of(context).push(
              PageRouteBuilder<Widget>(
                pageBuilder:
                    (BuildContext context, _, _) => AccountSearch(
                      type: _accountTypes[_tabController.index],
                    ),
                transitionDuration: animDurationEmphasizedDecelerate,
                reverseTransitionDuration: animDurationEmphasizedAccelerate,
                transitionsBuilder:
                    (
                      BuildContext context,
                      Animation<double> primaryAnimation,
                      Animation<double> secondaryAnimation,
                      Widget child,
                    ) => SharedAxisTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    ),
              ),

              /*    CupertinoPageRoute<bool>(
                builder: (BuildContext context) => AccountSearch(
                  type: _accountTypes[_tabController.index],
                ),
                fullscreenDialog: false,
              ),*/
            );
          },
        ),
      ];

      // Call once to set fab/page actions
      _handleTabChange();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();

    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      log.finer(() => "_handleTabChange(${_tabController.index})");
    }
  }

  static const List<AccountTypeFilter> _accountTypes = <AccountTypeFilter>[
    AccountTypeFilter.asset,
    AccountTypeFilter.expense,
    AccountTypeFilter.revenue,
    AccountTypeFilter.liabilities,
  ];
  final List<Widget> _tabPages =
      _accountTypes
          .map<Widget>((AccountTypeFilter t) => AccountDetails(accountType: t))
          .toList();

  @override
  Widget build(BuildContext context) {
    log.fine(() => "build(tab: ${_tabController.index})");
    return TabBarView(controller: _tabController, children: _tabPages);
  }
}

class AccountDetails extends StatefulWidget {
  const AccountDetails({super.key, required this.accountType});

  final AccountTypeFilter accountType;

  @override
  State<AccountDetails> createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<AccountDetails>
    with AutomaticKeepAliveClientMixin {
  final int _numberOfItemsPerRequest = 50;
  PagingState<int, AccountRead> _pagingState = PagingState<int, AccountRead>();

  final Logger log = Logger("Pages.Accounts.Details");

  /// Maps AccountTypeFilter to account type string for database queries.
  String _getAccountTypeString(AccountTypeFilter type) {
    switch (type) {
      case AccountTypeFilter.asset:
        return 'asset';
      case AccountTypeFilter.expense:
        return 'expense';
      case AccountTypeFilter.revenue:
        return 'revenue';
      case AccountTypeFilter.liabilities:
        return 'liability';
      default:
        return type.value ?? 'asset';
    }
  }

  /// Converts AccountEntity to AccountRead for UI compatibility.
  AccountRead _entityToAccountRead(AccountEntity entity) {
    // Parse type and role from string values
    ShortAccountTypeProperty? accountType;
    try {
      accountType = ShortAccountTypeProperty.values.firstWhere(
        (ShortAccountTypeProperty e) => e.value == entity.type,
        orElse: () => ShortAccountTypeProperty.asset,
      );
    } catch (_) {
      accountType = ShortAccountTypeProperty.asset;
    }

    AccountRoleProperty? accountRole;
    if (entity.accountRole != null && entity.accountRole!.isNotEmpty) {
      try {
        accountRole = AccountRoleProperty.values.firstWhere(
          (AccountRoleProperty e) => e.value == entity.accountRole,
          orElse: () => AccountRoleProperty.defaultasset,
        );
      } catch (_) {
        accountRole = AccountRoleProperty.defaultasset;
      }
    } else {
      // Default to 'defaultAsset' for asset accounts without a role
      accountRole = AccountRoleProperty.defaultasset;
    }

    return AccountRead(
      id: entity.id,
      type: 'accounts',
      attributes: AccountProperties(
        name: entity.name,
        type: accountType,
        accountRole: accountRole,
        currencyCode: entity.currencyCode,
        currentBalance: entity.currentBalance.toString(),
        iban: entity.iban,
        bic: entity.bic,
        accountNumber: entity.accountNumber,
        openingBalance: entity.openingBalance?.toString(),
        openingBalanceDate: entity.openingBalanceDate,
        notes: entity.notes,
        active: entity.active,
      ),
    );
  }

  Future<void> _fetchPage() async {
    if (_pagingState.isLoading) return;

    try {
      final AccountRepository accountRepository =
          context.read<AccountRepository>();

      final int pageKey = (_pagingState.keys?.last ?? 0) + 1;
      log.finest(
        "Getting page $pageKey (${_pagingState.pages?.length} pages loaded)",
      );

      // Use AccountRepository with cache-first strategy
      final String accountType = _getAccountTypeString(widget.accountType);
      final List<AccountEntity> accountEntities = await accountRepository
          .getByType(accountType);

      // Convert to AccountRead for UI compatibility
      final List<AccountRead> accountList =
          accountEntities.map(_entityToAccountRead).toList();

      // Implement simple pagination over local data
      final int startIndex = (pageKey - 1) * _numberOfItemsPerRequest;
      final int endIndex = startIndex + _numberOfItemsPerRequest;
      final List<AccountRead> pageItems =
          accountList.length > startIndex
              ? accountList.sublist(
                startIndex,
                endIndex > accountList.length ? accountList.length : endIndex,
              )
              : <AccountRead>[];

      final bool isLastPage = endIndex >= accountList.length;

      if (mounted) {
        setState(() {
          _pagingState = _pagingState.copyWith(
            pages: <List<AccountRead>>[...?_pagingState.pages, pageItems],
            keys: <int>[...?_pagingState.keys, pageKey],
            hasNextPage: !isLastPage,
            isLoading: false,
            error: null,
          );
        });
      }
    } catch (e, stackTrace) {
      log.severe("_fetchPage()", e, stackTrace);
      if (mounted) {
        setState(() {
          _pagingState = _pagingState.copyWith(error: e, isLoading: false);
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    log.fine(() => "build()");

    return RefreshIndicator(
      onRefresh:
          () => Future<void>.sync(
            () => setState(() {
              _pagingState = _pagingState.reset();
            }),
          ),
      child: PagedListView<int, AccountRead>(
        state: _pagingState,
        fetchNextPage: _fetchPage,
        builderDelegate: PagedChildBuilderDelegate<AccountRead>(
          animateTransitions: true,
          transitionDuration: animDurationStandard,
          invisibleItemsThreshold: 10,
          itemBuilder:
              (BuildContext context, AccountRead item, int index) =>
                  accountRowBuilder(
                    context,
                    item,
                    index,
                    () => setState(() {
                      _pagingState = _pagingState.reset();
                    }),
                  ),
        ),
      ),
    );
  }
}
