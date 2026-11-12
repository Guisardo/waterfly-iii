import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/extensions.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/pages/home/transactions/running_balance.dart';
import 'package:waterflyiii/settings.dart';

/// Balance of [accountId] counted from zero at [start], from local data.
Future<double> zeroStartAccountBalance(
  String accountId,
  DateTime start,
  DateTime? end,
) async {
  final Isar isar = await AppDatabase.instance;
  final List<TransactionRead> items = await TransactionRepository(
    isar,
  ).getByAccount(accountId, start, end);
  return windowBalanceTotal(items, accountId);
}

/// Balance and last activity shown at the end of an account row.
class AccountBalanceText extends StatelessWidget {
  const AccountBalanceText({
    super.key,
    required this.account,
    required this.currency,
    required this.amount,
  });

  final AccountRead account;
  final CurrencyRead currency;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    if (!settings.balanceStartAtZero) {
      return _text(context, amount);
    }
    final DateTime now = context
        .read<FireflyService>()
        .tzHandler
        .sNow()
        .clearTime();
    final DateTime start = transactionWindowStart(
      settings.transactionDateFilter,
      now,
    );
    final DateTime? end = settings.showFutureTXs ? null : now;
    return FutureBuilder<double>(
      key: ValueKey<String>('${account.id}|$start|$end'),
      future: zeroStartAccountBalance(account.id, start, end),
      builder: (BuildContext context, AsyncSnapshot<double> snapshot) =>
          _text(context, snapshot.data),
    );
  }

  Widget _text(BuildContext context, double? value) {
    return RichText(
      textAlign: TextAlign.end,
      maxLines: 2,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: <InlineSpan>[
          TextSpan(
            text: value == null ? "…" : currency.fmt(value),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: ((value ?? 0) < 0) ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const TextSpan(text: "\n"),
          TextSpan(
            text: account.attributes.lastActivity != null
                ? DateFormat.yMd().add_Hms().format(
                    account.attributes.lastActivity!.toLocal(),
                  )
                : S.of(context).generalNever,
          ),
        ],
      ),
    );
  }
}
