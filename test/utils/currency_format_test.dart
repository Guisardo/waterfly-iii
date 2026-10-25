import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/extensions.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';

CurrencyRead _currency(String code, String symbol, int places) => CurrencyRead(
  type: 'currencies',
  id: '1',
  attributes: CurrencyProperties(
    code: code,
    name: code,
    symbol: symbol,
    decimalPlaces: places,
  ),
);

void main() {
  group('CurrencyFormat.fmt', () {
    test('keeps the locale placement by default', () {
      expect(
        _currency('ARS', r'$', 2).fmt(48400, locale: 'es'),
        endsWith(r'$'),
      );
    });

    test('puts the symbol before the amount when requested', () {
      expect(
        _currency('ARS', r'$', 2).fmt(48400, locale: 'es', symbolFirst: true),
        '\$\u00A048.400,00',
      );
    });

    test('keeps the sign before the symbol for negative amounts', () {
      expect(
        _currency('ARS', r'$', 2).fmt(-100, locale: 'es', symbolFirst: true),
        '-\$\u00A0100,00',
      );
    });

    test('respects currencies without decimal places', () {
      expect(
        _currency(
          'JPY',
          '\u00A5',
          0,
        ).fmt(15000, locale: 'es', symbolFirst: true),
        '\u00A5\u00A015.000',
      );
    });
  });
}
