import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/notificationlistener.dart';

void main() {
  late FireflyIii apiService;

  late CurrencyRead cadCurrency;
  late CurrencyRead amsCurrency;

  setUpAll(() {
    final MockClient mockHttpClient = MockClient((http.Request request) async {
      if (request.url.path == '/v1/currencies') {
        return http.Response(
          json.encode(<String, Object>{
            "data": <Map<String, Object>>[
              <String, Object>{
                "type": "currencies",
                "id": "2",
                "attributes": <String, Object>{
                  "created_at": "2025-09-01T00:00:00+00:00",
                  "updated_at": "2025-09-01T00:00:00+00:00",
                  "enabled": true,
                  "primary": false,
                  "code": "CAD",
                  "name": "Canadian dollar",
                  "symbol": "\$",
                  "decimal_places": 2,
                },
              },
            ],
            "meta": <String, Map<String, int>>{
              "pagination": <String, int>{
                "total": 1,
                "count": 20,
                "per_page": 100,
                "current_page": 1,
                "total_pages": 1,
              },
            },
            "links": <String, String>{
              "self": "https://demo.firefly-iii.org/api/v1/OBJECT?&page=4",
              "first": "https://demo.firefly-iii.org/api/v1/OBJECT?&page=1",
              "next": "https://demo.firefly-iii.org/api/v1/OBJECT?&page=3",
              "prev": "https://demo.firefly-iii.org/api/v1/OBJECT?&page=2",
              "last": "https://demo.firefly-iii.org/api/v1/OBJECT?&page=12",
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final ChopperClient chopperClient = ChopperClient(
      client: mockHttpClient,
      services: <ChopperService>[FireflyIii.create(client: ChopperClient())],
      converter: $JsonSerializableConverter(),
    );

    apiService = chopperClient.getService<FireflyIii>(); // Pass the mock client

    cadCurrency = const CurrencyRead(
      type: "testCadCurrency",
      id: "testCadCurrency",
      attributes: CurrencyProperties(
        code: "CAD",
        name: "Canadian Dollar",
        symbol: r"$",
      ),
    );

    amsCurrency = const CurrencyRead(
      type: "testAmsCurrency",
      id: "testAmsCurrency",
      attributes: CurrencyProperties(
        code: "AMS",
        name: "Ankh-Morpork dollar",
        symbol: r"AM$",
      ),
    );
  });

  group('Payment notification formats', () {
    const CurrencyRead arsCurrency = CurrencyRead(
      type: 'currencies',
      id: 'ars',
      attributes: CurrencyProperties(
        code: 'ARS',
        name: 'Argentine peso',
        symbol: r'$',
      ),
    );
    test('Payment format 1', () async {
      final String text = notificationMoneyText(
        r'A MERPAGO*ABC con tu Tarjeta Santander Visa Crédito terminada en 8765, el 08/11/2026 a las 18:29 horas. (s.e.u.o.).',
        r'Pagaste $ 12.345,67',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 12345.67);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Payment format 2', () async {
      final String text = notificationMoneyText(
        r'Debitamos $ 123.567,89 por le pago a ABCDEF SA de tu Tarjeta Santander Visa Crédito terminada en 8765 (s.e.u.o.).',
        r'Aviso de débito automático',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 123567.89);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Payment format 3', () async {
      final String text = notificationMoneyText(
        r'Abcd Efghij pagó $ 123.456,78 a MERPAGO*CDE  con la tarjeta Santander American Express Crédito terminada en 5678, el 05/11/2026 a las 14:39 (s.e.u.o.).',
        r'Tu adicional hizo un consumo',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 123456.78);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Payment format 4', () async {
      final String text = notificationMoneyText(
        r'Debitamos $ 1.234,56 por el pago a MERPAGO*MELI de la Tarjeta Santander Visa Crédito terminada en 8760 de Abcd Efghij (s.e.u.o.).',
        r'Débito automático de tu adicional',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 1234.56);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Payment format 5', () async {
      final String text = notificationMoneyText(
        r'Enviaste $ 654.321,09 a Abc Defg Hij .',
        r'Transferiste con éxito',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 654321.09);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Payment format 6', () async {
      final String text = notificationMoneyText(
        r'Pagaste $123456.56 a ASBCD',
        r'Se aprobó tu pago',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 123456.56);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Payment format 7', () async {
      final String text = notificationMoneyText(
        r'Paid $12.34',
        r'Balance $987.65',
      );
      expect(
        rFindMoney
            .allMatches(text)
            .any(
              (RegExpMatch match) =>
                  (match.namedGroup('preCurrency')?.contains(r'$') ?? false) ||
                  (match.namedGroup('postCurrency')?.contains(r'$') ?? false),
            ),
        isTrue,
      );
      final (CurrencyRead? currency, double amount) =
          await parseNotificationText(apiService, text, arsCurrency);
      expect(amount, 12.34);
      expect(currency?.attributes.code, 'ARS');
    });
    test('Explicit foreign code beats shared local symbol', () async {
      final (
        CurrencyRead? currency,
        double amount,
      ) = await parseNotificationText(
        apiService,
        r'Paid $4.99 CAD at VENDOR.',
        arsCurrency,
      );
      expect(amount, 4.99);
      expect(currency?.attributes.code, 'CAD');
    });
  });

  group('Notification Unicode presentation', () {
    const CurrencyRead localCurrency = CurrencyRead(
      type: 'currencies',
      id: 'ars',
      attributes: CurrencyProperties(
        code: 'ARS',
        name: 'Argentine peso',
        symbol: r'$',
      ),
    );
    final Map<String, String> cases = <String, String>{
      'emoji before currency': '\u{1F4B3} Pagaste \$ 12.345,67',
      'emoji after amount': 'Pagaste \$ 12.345,67 \u{2705}',
      'nonbreaking currency space': 'Pagaste \$\u00a012.345,67',
      'narrow nonbreaking currency space': 'Pagaste \$\u202f12.345,67',
      'nonbreaking grouping space': 'Pagaste \$ 12\u00a0345,67',
      'narrow nonbreaking grouping space': 'Pagaste \$ 12\u202f345,67',
    };
    for (final MapEntry<String, String> entry in cases.entries) {
      for (final bool titleOnly in <bool>[false, true]) {
        test('${entry.key}, titleOnly=$titleOnly', () async {
          final String text = notificationMoneyText(
            titleOnly ? '' : entry.value,
            titleOnly ? entry.value : 'Payment notification',
          );
          expect(
            rFindMoney
                .allMatches(text)
                .any(
                  (RegExpMatch match) =>
                      (match.namedGroup('preCurrency')?.isNotEmpty ?? false) ||
                      (match.namedGroup('postCurrency')?.isNotEmpty ?? false),
                ),
            isTrue,
          );
          final (CurrencyRead? currency, double amount) =
              await parseNotificationText(apiService, text, localCurrency);
          expect(amount, 12345.67);
          expect(currency?.attributes.code, 'ARS');
        });
      }
    }
  });

  group('Direct parser Unicode spacing', () {
    const CurrencyRead localCurrency = CurrencyRead(
      type: 'currencies',
      id: 'ars',
      attributes: CurrencyProperties(
        code: 'ARS',
        name: 'Argentine peso',
        symbol: r'$',
      ),
    );
    for (final String space in <String>['\u00a0', '\u202f']) {
      test('Direct parsing space ${space.codeUnitAt(0)}', () async {
        final (
          CurrencyRead? currency,
          double amount,
        ) = await parseNotificationText(
          apiService,
          'Pagaste \$${space}12.345,67',
          localCurrency,
        );
        expect(amount, 12345.67);
        expect(currency?.attributes.code, 'ARS');
      });
    }
    test('Normalization preserves emoji punctuation and line breaks', () {
      const String original = '\u{1F4B3} Paid \$12.34!\nBalance: \$56.78';
      expect(normalizeNotificationMoneyText(original), original);
    });
    test('Normalization is idempotent', () {
      const String original = 'Pagaste \$\u00a012\u202f345,67';
      final String normalized = normalizeNotificationMoneyText(original);
      expect(normalized, r'Pagaste $ 12 345,67');
      expect(normalizeNotificationMoneyText(normalized), normalized);
    });
  });

  group('Notification listener', () {
    test('- Text parsing tests', () async {
      CurrencyRead? extractedCurrency;
      double extractedAmount;

      // Test with empty input
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"",
        amsCurrency,
      );
      expect(extractedAmount, 0.0);

      // Test with input containing no numeric values
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase was made from RBC credit card at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 0.0);

      // Test with amount formatted as ##
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $4 CAD was made at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 4);

      // Test with amount formatted as ##.#
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $4.99 CAD was made at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 4.99);

      // Test with amount formatted as ##,#
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $4,99 CAD was made at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 4.99);

      // Test with amount formatted as #.###,#
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $1.444,99 CAD was made at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 1444.99);

      // Test with amount formatted as #,###.#
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $1,444.99 CAD was made at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 1444.99);

      // Test with local currency matching
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $4.99 CAD was made at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 4.99);
      expect(extractedCurrency?.attributes.code, cadCurrency.attributes.code);

      // Test with local currency not matching
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $4.99 CAD was made at VENDOR.",
        amsCurrency,
      );
      expect(extractedAmount, 4.99);
      expect(extractedCurrency?.attributes.code, "CAD");

      // Test with currency information in format that won't match either the
      // local or remote currency definitions
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of C$4.99 was made from at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 4.99);
      expect(extractedCurrency, null);

      // Test with multiple values that would match the regex
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of $4.99 CAD was made from RBC credit card 9999 at VENDOR.",
        cadCurrency,
      );
      expect(extractedAmount, 4.99);
      expect(extractedCurrency?.attributes.code, "CAD");

      // Test with multiple values that would match the regex, where the actual
      // amount is not the first match
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase was made from RBC credit card 9999 at VENDOR for $4.99 CAD.",
        cadCurrency,
      );
      expect(extractedAmount, 4.99);
      expect(extractedCurrency?.attributes.code, "CAD");

      // Test other example strings provided by users
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"LINE pay purchase NT$ 80. Payment complete. Merchant: vendor.",
        cadCurrency,
      );
      expect(extractedAmount, 80);

      // Test with unknown/invalid currency (RON)
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"Paid RON33.97 at Mega Image. RON balance: RON127.56",
        cadCurrency,
      );
      expect(extractedAmount, 33.97);
      expect(extractedCurrency?.attributes.code, null);

      // Test with known/default currency (CAD)
      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"Paid CAD33.97 at Mega Image. CAD balance: CAD127.56",
        cadCurrency,
      );
      expect(extractedAmount, 33.97);
      expect(extractedCurrency?.attributes.code, "CAD");

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"Compra por $7.990 con T.Crédito ****8697 en MER-CADOPAGO *PATRICIO Las Condes CHL el 05/06/2025 17:28. Revisa Saldos y Movimientos en App Mi Bianco o Banco en Línea.",
        cadCurrency,
      );
      expect(extractedAmount, 7.99);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"U.S. Bank Visa Debit Card 0544 Caseys #2309 BLAINE US $8.20",
        cadCurrency,
      );
      expect(extractedAmount, 8.20);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"€12.34 with Card •••• 9876",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"Sie haben €12,34 bei Some Store mit Ihrer American Express Karte mit den Enziffern 98765 ausgegeben.",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"07.09.17 17:30 Credit Card Virtual*9876\nсплата за товар/послугу 9876.54 EUR LIQ-PAYDEMSOKIRA GO. Доступна сума: 12.34 EUR",
        cadCurrency,
      );
      expect(extractedAmount, 9876.54);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"€ 12,34 afgeschreven van *123. Jouw actuele saldo is € +987,65.",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        "Vous avez envoyé 1.234F\nA Some Store (987654321)\n07/09/2017 à 17h30\nFrais 1234F\nNouveau solde: 9.876F\nAvec ABC\nABCDEFGHIJKL",
        cadCurrency,
      );
      expect(extractedAmount, 1.234);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"Payment of Rs 12.34 using Amazon Pay Balance is successful at Amazon.in. Updated Balance: Rs 9876.54. For help/stmt: https://www.example.com/cstxn",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"A purchase of €12.34 made using your Tangerine Credit Card at Some Store on September 07, 2017",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"Du hast 12,34 € von Some Store erhalten",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"12,34 € bei Some Store ausgegeben",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"There was an authorization for $12.34 at WALMART STORE #1234 on account credit_card_number_here at 6:59 pm ET. If you didn't do this, call 1-xxx-xxx-xxxx,",
        cadCurrency,
      );
      expect(extractedAmount, 12.34);
      expect(extractedCurrency?.attributes.code, "CAD");

      (extractedCurrency, extractedAmount) = await parseNotificationText(
        apiService,
        r"已支付¥4.00",
        cadCurrency,
      );
      expect(extractedAmount, 4);
    });
  });
}
