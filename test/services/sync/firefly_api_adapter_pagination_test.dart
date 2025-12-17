import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/models/paginated_result.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';

/// Comprehensive tests for pagination models and API adapter utilities.
///
/// Tests cover:
/// - PaginatedResult model functionality
/// - ApiException class
/// - Edge cases and boundary conditions
///
/// Note: Full integration tests for FireflyApiAdapter and DateRangeIterator
/// require a running Firefly III server or extensive mocking of the generated
/// Swagger client. Those tests are covered in integration tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaginatedResult', () {
    group('hasMore', () {
      test('should return true when more pages exist', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item1', 'item2'],
          total: 100,
          currentPage: 1,
          totalPages: 5,
          perPage: 20,
        );

        expect(result.hasMore, isTrue);
      });

      test('should return false when on last page', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item1'],
          total: 100,
          currentPage: 5,
          totalPages: 5,
          perPage: 20,
        );

        expect(result.hasMore, isFalse);
      });

      test('should return false when current page equals total pages', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['only-item'],
          total: 1,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );

        expect(result.hasMore, isFalse);
        expect(result.currentPage, equals(result.totalPages));
      });

      test('should return false when current page exceeds total pages', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>[],
          total: 0,
          currentPage: 2,
          totalPages: 1,
          perPage: 50,
        );

        expect(result.hasMore, isFalse);
      });
    });

    group('progressPercent', () {
      test('should calculate 50% when on page 2 of 4', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item1'],
          total: 100,
          currentPage: 2,
          totalPages: 4,
          perPage: 25,
        );

        expect(result.progressPercent, equals(50.0));
      });

      test('should calculate 100% when on last page', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item1'],
          total: 100,
          currentPage: 4,
          totalPages: 4,
          perPage: 25,
        );

        expect(result.progressPercent, equals(100.0));
      });

      test('should calculate 25% when on page 1 of 4', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item1'],
          total: 100,
          currentPage: 1,
          totalPages: 4,
          perPage: 25,
        );

        expect(result.progressPercent, equals(25.0));
      });

      test('should return 100% when total is 0', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>[],
          total: 0,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );

        expect(result.progressPercent, equals(100.0));
      });

      test('should handle single page result', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['only-item'],
          total: 1,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );

        expect(result.progressPercent, equals(100.0));
      });
    });

    group('data access', () {
      test('should provide access to data list', () {
        final List<String> testData = <String>['a', 'b', 'c'];
        final PaginatedResult<String> result = PaginatedResult<String>(
          data: testData,
          total: 3,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );

        expect(result.data, equals(testData));
        expect(result.data.length, equals(3));
      });

      test('should handle empty data', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>[],
          total: 0,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );

        expect(result.data, isEmpty);
      });

      test('should work with different generic types', () {
        // Test with int
        final PaginatedResult<int> intResult = const PaginatedResult<int>(
          data: <int>[1, 2, 3],
          total: 3,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );
        expect(intResult.data, equals(<int>[1, 2, 3]));

        // Test with Map
        final PaginatedResult<Map<String, dynamic>> mapResult =
            const PaginatedResult<Map<String, dynamic>>(
              data: <Map<String, dynamic>>[
                <String, dynamic>{'id': '1'},
                <String, dynamic>{'id': '2'},
              ],
              total: 2,
              currentPage: 1,
              totalPages: 1,
              perPage: 50,
            );
        expect(mapResult.data.length, equals(2));
        expect(mapResult.data[0]['id'], equals('1'));
      });
    });

    group('pagination metadata', () {
      test('should store total correctly', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item'],
          total: 1000,
          currentPage: 1,
          totalPages: 20,
          perPage: 50,
        );

        expect(result.total, equals(1000));
      });

      test('should store currentPage correctly', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item'],
          total: 100,
          currentPage: 5,
          totalPages: 10,
          perPage: 10,
        );

        expect(result.currentPage, equals(5));
      });

      test('should store totalPages correctly', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item'],
          total: 100,
          currentPage: 1,
          totalPages: 10,
          perPage: 10,
        );

        expect(result.totalPages, equals(10));
      });

      test('should store perPage correctly', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item'],
          total: 100,
          currentPage: 1,
          totalPages: 4,
          perPage: 25,
        );

        expect(result.perPage, equals(25));
      });
    });

    group('toString', () {
      test('should provide meaningful toString output', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item1', 'item2'],
          total: 100,
          currentPage: 2,
          totalPages: 5,
          perPage: 20,
        );

        final String stringRep = result.toString();

        expect(stringRep, contains('page 2/5'));
        expect(stringRep, contains('2 items'));
        expect(stringRep, contains('100 total'));
      });

      test('should handle edge cases in toString', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>[],
          total: 0,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        );

        final String stringRep = result.toString();

        expect(stringRep, contains('page 1/1'));
        expect(stringRep, contains('0 items'));
        expect(stringRep, contains('0 total'));
      });
    });

    group('edge cases', () {
      test('should handle large page numbers', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>['item'],
          total: 1000000,
          currentPage: 9999,
          totalPages: 10000,
          perPage: 100,
        );

        expect(result.hasMore, isTrue);
        expect(result.currentPage, equals(9999));
        expect(result.totalPages, equals(10000));
      });

      test('should handle zero perPage', () {
        final PaginatedResult<String> result = const PaginatedResult<String>(
          data: <String>[],
          total: 0,
          currentPage: 1,
          totalPages: 1,
          perPage: 0,
        );

        expect(result.perPage, equals(0));
        expect(result.hasMore, isFalse);
      });
    });
  });

  group('ApiException', () {
    group('construction', () {
      test('should contain error message', () {
        final ApiException exception = ApiException('Test error');

        expect(exception.message, equals('Test error'));
      });

      test('should contain status code when provided', () {
        final ApiException exception = ApiException(
          'Not found',
          statusCode: 404,
        );

        expect(exception.statusCode, equals(404));
      });

      test('should contain headers when provided', () {
        final ApiException exception = ApiException(
          'Rate limited',
          statusCode: 429,
          headers: <String, String>{'Retry-After': '60'},
        );

        expect(exception.headers, isNotNull);
        expect(exception.headers!['Retry-After'], equals('60'));
      });

      test('should allow null status code', () {
        final ApiException exception = ApiException('Generic error');

        expect(exception.statusCode, isNull);
      });

      test('should allow null headers', () {
        final ApiException exception = ApiException('Error', statusCode: 500);

        expect(exception.headers, isNull);
      });
    });

    group('toString', () {
      test('should include message in toString', () {
        final ApiException exception = ApiException('Test error message');

        expect(exception.toString(), contains('Test error message'));
      });

      test('should include status code in toString when present', () {
        final ApiException exception = ApiException(
          'Not found',
          statusCode: 404,
        );

        expect(exception.toString(), contains('404'));
      });

      test('should not include status code notation when absent', () {
        final ApiException exception = ApiException('Generic error');

        expect(exception.toString(), contains('Generic error'));
        expect(exception.toString(), isNot(contains('status:')));
      });
    });

    group('Exception implementation', () {
      test('should be throwable', () {
        expect(() => throw ApiException('Test'), throwsA(isA<ApiException>()));
      });

      test('should be catchable as Exception', () {
        expect(() => throw ApiException('Test'), throwsA(isA<Exception>()));
      });

      test('should preserve message when caught', () {
        try {
          throw ApiException('Preserved message', statusCode: 500);
        } on ApiException catch (e) {
          expect(e.message, equals('Preserved message'));
          expect(e.statusCode, equals(500));
        }
      });
    });

    group('HTTP status code semantics', () {
      test('should represent client errors (4xx)', () {
        final ApiException badRequest = ApiException(
          'Bad request',
          statusCode: 400,
        );
        final ApiException unauthorized = ApiException(
          'Unauthorized',
          statusCode: 401,
        );
        final ApiException forbidden = ApiException(
          'Forbidden',
          statusCode: 403,
        );
        final ApiException notFound = ApiException(
          'Not found',
          statusCode: 404,
        );

        expect(badRequest.statusCode, equals(400));
        expect(unauthorized.statusCode, equals(401));
        expect(forbidden.statusCode, equals(403));
        expect(notFound.statusCode, equals(404));
      });

      test('should represent server errors (5xx)', () {
        final ApiException internalError = ApiException(
          'Internal server error',
          statusCode: 500,
        );
        final ApiException badGateway = ApiException(
          'Bad gateway',
          statusCode: 502,
        );
        final ApiException serviceUnavailable = ApiException(
          'Service unavailable',
          statusCode: 503,
        );

        expect(internalError.statusCode, equals(500));
        expect(badGateway.statusCode, equals(502));
        expect(serviceUnavailable.statusCode, equals(503));
      });

      test('should handle rate limiting (429)', () {
        final ApiException rateLimited = ApiException(
          'Too many requests',
          statusCode: 429,
          headers: <String, String>{
            'Retry-After': '120',
            'X-RateLimit-Remaining': '0',
          },
        );

        expect(rateLimited.statusCode, equals(429));
        expect(rateLimited.headers!['Retry-After'], equals('120'));
        expect(rateLimited.headers!['X-RateLimit-Remaining'], equals('0'));
      });
    });
  });

  group('PaginatedResult with Map data (API simulation)', () {
    test('should work with transaction-like data', () {
      final PaginatedResult<Map<String, dynamic>> result =
          const PaginatedResult<Map<String, dynamic>>(
            data: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': '123',
                'type': 'transactions',
                'attributes': <String, dynamic>{
                  'description': 'Test transaction',
                  'amount': '100.00',
                  'date': '2024-12-01',
                  'updated_at': '2024-12-15T10:00:00Z',
                },
              },
              <String, dynamic>{
                'id': '124',
                'type': 'transactions',
                'attributes': <String, dynamic>{
                  'description': 'Another transaction',
                  'amount': '50.00',
                  'date': '2024-12-02',
                  'updated_at': '2024-12-15T11:00:00Z',
                },
              },
            ],
            total: 150,
            currentPage: 1,
            totalPages: 3,
            perPage: 50,
          );

      expect(result.data.length, equals(2));
      expect(result.hasMore, isTrue);
      expect(result.data[0]['id'], equals('123'));
      expect(
        result.data[0]['attributes']['description'],
        equals('Test transaction'),
      );
    });

    test('should work with account-like data', () {
      final PaginatedResult<Map<String, dynamic>> result =
          const PaginatedResult<Map<String, dynamic>>(
            data: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'acc-1',
                'type': 'accounts',
                'attributes': <String, dynamic>{
                  'name': 'Checking Account',
                  'type': 'asset',
                  'current_balance': '1000.00',
                  'updated_at': '2024-12-15T10:00:00Z',
                },
              },
            ],
            total: 10,
            currentPage: 1,
            totalPages: 1,
            perPage: 50,
          );

      expect(result.data.length, equals(1));
      expect(result.hasMore, isFalse);
      expect(result.data[0]['attributes']['name'], equals('Checking Account'));
    });

    test('should support extracting server_updated_at for sync', () {
      final PaginatedResult<Map<String, dynamic>> result =
          const PaginatedResult<Map<String, dynamic>>(
            data: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': '1',
                'attributes': <String, dynamic>{
                  'updated_at': '2024-12-15T10:00:00Z',
                },
              },
              <String, dynamic>{
                'id': '2',
                'attributes': <String, dynamic>{
                  'updated_at': '2024-12-15T11:00:00Z',
                },
              },
              <String, dynamic>{
                'id': '3',
                'attributes': <String, dynamic>{
                  'updated_at': '2024-12-15T09:00:00Z',
                },
              },
            ],
            total: 3,
            currentPage: 1,
            totalPages: 1,
            perPage: 50,
          );

      // Simulate incremental sync timestamp extraction
      final List<DateTime> timestamps =
          result.data
              .map((Map<String, dynamic> item) {
                final String? updatedAt =
                    (item['attributes'] as Map<String, dynamic>?)?['updated_at']
                        as String?;
                return updatedAt != null ? DateTime.parse(updatedAt) : null;
              })
              .whereType<DateTime>()
              .toList();

      expect(timestamps.length, equals(3));
      expect(timestamps[0], equals(DateTime.parse('2024-12-15T10:00:00Z')));
      expect(timestamps[1], equals(DateTime.parse('2024-12-15T11:00:00Z')));
      expect(timestamps[2], equals(DateTime.parse('2024-12-15T09:00:00Z')));
    });
  });
}
