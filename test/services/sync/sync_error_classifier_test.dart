import 'package:chopper/chopper.dart' show Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:waterflyiii/services/sync/sync_error_classifier.dart';

/// Builds a minimal fake Chopper [Response] with the given HTTP status code.
Response<dynamic> _response(int statusCode) =>
    Response<dynamic>(http.Response('', statusCode), null);

void main() {
  group('SyncErrorClassifier', () {
    // -----------------------------------------------------------------------
    // isNetworkError
    // -----------------------------------------------------------------------

    group('isNetworkError', () {
      test('returns true for SocketException', () {
        expect(
          SyncErrorClassifier.isNetworkError(
            Exception('SocketException: Failed host lookup'),
          ),
          isTrue,
        );
      });

      test('returns true for connection refused string', () {
        expect(
          SyncErrorClassifier.isNetworkError(Exception('Connection refused')),
          isTrue,
        );
      });

      test('returns true for connection reset string', () {
        expect(
          SyncErrorClassifier.isNetworkError(
            Exception('connection reset by peer'),
          ),
          isTrue,
        );
      });

      test('returns true for connection timed out string', () {
        expect(
          SyncErrorClassifier.isNetworkError(Exception('connection timed out')),
          isTrue,
        );
      });

      test('returns true for no internet connection string', () {
        expect(
          SyncErrorClassifier.isNetworkError(
            Exception('No internet connection'),
          ),
          isTrue,
        );
      });

      test('returns true for network is unreachable string', () {
        expect(
          SyncErrorClassifier.isNetworkError(
            Exception('Network is unreachable'),
          ),
          isTrue,
        );
      });

      test('returns true for cronet string', () {
        expect(
          SyncErrorClassifier.isNetworkError(Exception('Cronet error')),
          isTrue,
        );
      });

      test('returns true for ClientException string', () {
        expect(
          SyncErrorClassifier.isNetworkError(
            Exception('ClientException: Failed to connect'),
          ),
          isTrue,
        );
      });

      test('returns true for err_network_changed string', () {
        expect(
          SyncErrorClassifier.isNetworkError(Exception('err_network_changed')),
          isTrue,
        );
      });

      test('returns true for plain string with socketexception', () {
        expect(
          SyncErrorClassifier.isNetworkError('socketexception: something'),
          isTrue,
        );
      });

      test('returns false for unrelated exception', () {
        expect(
          SyncErrorClassifier.isNetworkError(Exception('some other error')),
          isFalse,
        );
      });

      test('returns false for 500 response', () {
        expect(SyncErrorClassifier.isNetworkError(_response(500)), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // isTimeoutError
    // -----------------------------------------------------------------------

    group('isTimeoutError', () {
      test('returns true for HTTP 408 response', () {
        expect(SyncErrorClassifier.isTimeoutError(_response(408)), isTrue);
      });

      test('returns false for HTTP 200 response', () {
        expect(SyncErrorClassifier.isTimeoutError(_response(200)), isFalse);
      });

      test('returns false for HTTP 500 response', () {
        expect(SyncErrorClassifier.isTimeoutError(_response(500)), isFalse);
      });

      test('returns true for TimeoutException string', () {
        expect(
          SyncErrorClassifier.isTimeoutError(Exception('TimeoutException')),
          isTrue,
        );
      });

      test('returns true for timed out string', () {
        expect(
          SyncErrorClassifier.isTimeoutError(Exception('request timed out')),
          isTrue,
        );
      });

      test('returns true for deadline exceeded string', () {
        expect(
          SyncErrorClassifier.isTimeoutError(
            Exception('Deadline exceeded: 30s'),
          ),
          isTrue,
        );
      });

      test('returns false for unrelated error', () {
        expect(
          SyncErrorClassifier.isTimeoutError(Exception('bad request')),
          isFalse,
        );
      });
    });

    // -----------------------------------------------------------------------
    // isServerError
    // -----------------------------------------------------------------------

    group('isServerError', () {
      test('returns true for HTTP 500 response', () {
        expect(SyncErrorClassifier.isServerError(_response(500)), isTrue);
      });

      test('returns true for HTTP 502 response', () {
        expect(SyncErrorClassifier.isServerError(_response(502)), isTrue);
      });

      test('returns true for HTTP 503 response', () {
        expect(SyncErrorClassifier.isServerError(_response(503)), isTrue);
      });

      test('returns true for HTTP 504 response', () {
        expect(SyncErrorClassifier.isServerError(_response(504)), isTrue);
      });

      test('returns true for HTTP 429 response (rate limiting)', () {
        expect(SyncErrorClassifier.isServerError(_response(429)), isTrue);
      });

      test('returns false for HTTP 400 response', () {
        expect(SyncErrorClassifier.isServerError(_response(400)), isFalse);
      });

      test('returns false for HTTP 200 response', () {
        expect(SyncErrorClassifier.isServerError(_response(200)), isFalse);
      });

      test('returns false for HTTP 404 response', () {
        expect(SyncErrorClassifier.isServerError(_response(404)), isFalse);
      });

      test('returns true for string containing 500', () {
        expect(
          SyncErrorClassifier.isServerError('Internal Server Error 500'),
          isTrue,
        );
      });

      test('returns false for unrelated string', () {
        expect(
          SyncErrorClassifier.isServerError('some generic error'),
          isFalse,
        );
      });
    });

    // -----------------------------------------------------------------------
    // isAuthError
    // -----------------------------------------------------------------------

    group('isAuthError', () {
      test('returns true for HTTP 401 response', () {
        expect(SyncErrorClassifier.isAuthError(_response(401)), isTrue);
      });

      test('returns true for HTTP 403 response', () {
        expect(SyncErrorClassifier.isAuthError(_response(403)), isTrue);
      });

      test('returns false for HTTP 200 response', () {
        expect(SyncErrorClassifier.isAuthError(_response(200)), isFalse);
      });

      test('returns false for HTTP 500 response', () {
        expect(SyncErrorClassifier.isAuthError(_response(500)), isFalse);
      });

      test('returns true for unauthorized string', () {
        expect(
          SyncErrorClassifier.isAuthError(Exception('Unauthorized access')),
          isTrue,
        );
      });

      test('returns true for forbidden string', () {
        expect(
          SyncErrorClassifier.isAuthError(Exception('Forbidden resource')),
          isTrue,
        );
      });

      test('returns true for 401 in string', () {
        expect(
          SyncErrorClassifier.isAuthError('Error 401: token expired'),
          isTrue,
        );
      });

      test('returns false for unrelated error', () {
        expect(
          SyncErrorClassifier.isAuthError(Exception('connection refused')),
          isFalse,
        );
      });
    });

    // -----------------------------------------------------------------------
    // isConflictError
    // -----------------------------------------------------------------------

    group('isConflictError', () {
      test('returns true for HTTP 409 response', () {
        expect(SyncErrorClassifier.isConflictError(_response(409)), isTrue);
      });

      test('returns false for HTTP 200 response', () {
        expect(SyncErrorClassifier.isConflictError(_response(200)), isFalse);
      });

      test('returns false for HTTP 400 response', () {
        expect(SyncErrorClassifier.isConflictError(_response(400)), isFalse);
      });

      test('returns true for string containing 409', () {
        expect(
          SyncErrorClassifier.isConflictError('HTTP 409 Conflict'),
          isTrue,
        );
      });

      test('returns true for string containing Conflict', () {
        expect(
          SyncErrorClassifier.isConflictError('Conflict detected'),
          isTrue,
        );
      });

      test('returns true for exception containing Conflict', () {
        expect(
          SyncErrorClassifier.isConflictError(
            Exception('Conflict: duplicate resource'),
          ),
          isTrue,
        );
      });

      test('returns false for unrelated exception', () {
        expect(
          SyncErrorClassifier.isConflictError(Exception('some other error')),
          isFalse,
        );
      });
    });
  });
}
