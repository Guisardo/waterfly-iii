import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/pages/home/transactions/running_balance.dart';

TransactionRead tx(
  String id,
  String type,
  String amount, {
  String? source,
  String? destination,
}) => TransactionRead.fromJson(<String, dynamic>{
  'type': 'transactions',
  'id': id,
  'attributes': <String, dynamic>{
    'transactions': <dynamic>[
      <String, dynamic>{
        'type': type,
        'date': '2026-11-01T00:00:00Z',
        'amount': amount,
        'description': id,
        'source_id': source,
        'destination_id': destination,
      },
    ],
  },
  'links': <String, dynamic>{'self': 'https://example.com/$id'},
});

void main() {
  const String account = 'a1';

  test('effects follow transaction direction', () {
    expect(transactionBalanceEffect(tx('w', 'withdrawal', '30'), account), -30);
    expect(transactionBalanceEffect(tx('d', 'deposit', '100'), account), 100);
    expect(
      transactionBalanceEffect(
        tx('in', 'transfer', '50', source: 'b', destination: account),
        account,
      ),
      50,
    );
    expect(
      transactionBalanceEffect(
        tx('out', 'transfer', '20', source: account, destination: 'b'),
        account,
      ),
      -20,
    );
  });

  test('descending walk starts at window total and ends at zero', () {
    final List<TransactionRead> newestFirst = <TransactionRead>[
      tx('w', 'withdrawal', '30'),
      tx('d', 'deposit', '100'),
      tx('in', 'transfer', '50', source: 'b', destination: account),
    ];
    double balance = windowBalanceTotal(newestFirst, account);
    final List<double> shown = <double>[];
    for (final TransactionRead item in newestFirst) {
      shown.add(balance);
      balance -= transactionBalanceEffect(item, account);
    }
    expect(shown, <double>[120, 150, 50]);
    expect(balance, 0);
  });

  test('empty window totals zero', () {
    expect(windowBalanceTotal(<TransactionRead>[], account), 0);
  });
}
