import 'dart:convert';

import 'package:chopper/chopper.dart' show Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';

import '../helpers/mock_api.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json',
};

String _pagedBody(List<Object?> data) {
  return jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{
      'pagination': <String, Object?>{
        'total': data.length,
        'count': data.length,
        'per_page': 50,
        'current_page': 1,
        'total_pages': 1,
      },
    },
    'links': <String, Object?>{
      'self': 'http://test.firefly.local/api/v1/test?page=1',
      'first': 'http://test.firefly.local/api/v1/test?page=1',
      'last': 'http://test.firefly.local/api/v1/test?page=1',
    },
  });
}

Future<Uri> _requestTransactionList(MockFireflyServiceHelper helper) async {
  final List<Uri> seen = <Uri>[];
  helper.mockHttpClient.setHandler('/v1/transactions', (
    http.BaseRequest request,
  ) {
    seen.add(request.url);
    return http.Response(_pagedBody(<Object?>[]), 200, headers: _jsonHeaders);
  });
  await helper.mockApi.v1TransactionsGet(
    limit: 50,
    page: 1,
    createdSince: '2026-06-15',
    createdUntil: '2026-06-30',
    updatedSince: '2026-06-15T10:00:00+02:00',
    updatedUntil: '2026-06-30T23:59:59Z',
    sort: 'updated_at',
  );
  expect(seen, hasLength(1));
  return seen.single;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('incremental sync API', () {
    late MockFireflyServiceHelper helper;

    setUp(() {
      helper = MockFireflyServiceHelper();
    });

    test(
      'the transaction list sends the timestamp filters and the sort',
      () async {
        final Uri url = await _requestTransactionList(helper);
        final Map<String, String> query = url.queryParameters;

        expect(query['created_since'], '2026-06-15');
        expect(query['created_until'], '2026-06-30');
        expect(query['updated_since'], '2026-06-15T10:00:00+02:00');
        expect(query['updated_until'], '2026-06-30T23:59:59Z');
        expect(query['sort'], 'updated_at');
        expect(query['limit'], '50');
        expect(query['page'], '1');
      },
    );

    test('the plus sign of an offset travels encoded', () async {
      final Uri url = await _requestTransactionList(helper);

      expect(url.query.contains('+'), isFalse);
    });

    test('the deleted items list is requested and parsed', () async {
      final List<Uri> seen = <Uri>[];
      helper.mockHttpClient.setHandler('/v1/data/deleted', (
        http.BaseRequest request,
      ) {
        seen.add(request.url);
        return http.Response(
          _pagedBody(<Object?>[
            <String, Object?>{
              'type': 'deleted-items',
              'id': '5',
              'attributes': <String, Object?>{
                'entity': 'transactions',
                'deleted_at': '2026-06-15T10:00:00+02:00',
              },
            },
            <String, Object?>{
              'type': 'deleted-items',
              'id': '9',
              'attributes': <String, Object?>{
                'entity': 'transactions',
                'deleted_at': '2026-06-16T08:30:00+02:00',
              },
            },
          ]),
          200,
          headers: _jsonHeaders,
        );
      });

      final Response<DeletedItemArray> response = await helper.mockApi
          .v1DataDeletedGet(
            since: '2026-06-15T10:00:00+02:00',
            types: 'transactions',
            limit: 50,
            page: 1,
          );

      expect(seen, hasLength(1));
      expect(seen.single.path, endsWith('/v1/data/deleted'));
      expect(seen.single.queryParameters['types'], 'transactions');
      expect(seen.single.queryParameters['since'], '2026-06-15T10:00:00+02:00');
      expect(
        response.isSuccessful,
        isTrue,
        reason: '${response.statusCode} ${response.error}',
      );
      final DeletedItemArray body = response.body!;
      expect(body.data, hasLength(2));
      expect(body.data.first.id, '5');
      final Map<String, dynamic> first = body.data.first.attributes.toJson();
      expect(first['entity'], 'transactions');
      expect(first['deleted_at'], isNotNull);
    });

    test('the about endpoint reports the capabilities', () async {
      helper.mockHttpClient.setHandler('/v1/about', (http.BaseRequest request) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'version': '6.6.3',
              'api_version': '6.6.3',
              'php_version': '8.5.12',
              'os': 'Linux',
              'driver': 'sqlite',
              'capabilities': <String>[
                'incremental.transactions',
                'deleted_items',
              ],
            },
          }),
          200,
          headers: _jsonHeaders,
        );
      });

      final Response<SystemInfo> response = await helper.mockApi.v1AboutGet();

      expect(response.body?.data?.capabilities, <String>[
        'incremental.transactions',
        'deleted_items',
      ]);
    });

    test('a server without the field reports no capabilities', () async {
      helper.mockHttpClient.setHandler('/v1/about', (http.BaseRequest request) {
        return http.Response(
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'version': '6.4.14',
              'api_version': '6.4.14',
              'php_version': '8.4.1',
              'os': 'Linux',
              'driver': 'mysql',
            },
          }),
          200,
          headers: _jsonHeaders,
        );
      });

      final Response<SystemInfo> response = await helper.mockApi.v1AboutGet();

      expect(response.isSuccessful, isTrue);
      expect(response.body?.data?.capabilities ?? <String>[], isEmpty);
    });
  });
}
