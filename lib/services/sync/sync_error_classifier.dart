import 'package:chopper/chopper.dart' show Response;

/// Utility class for classifying sync-related errors into actionable categories.
///
/// All methods are static and accept a [dynamic] error value, which may be a
/// [Response], an [Exception], or any other object whose [toString] representation
/// is inspected as a fallback.
///
/// The classification logic is the union of checks that were previously duplicated
/// across [SyncService] and [UploadService].
class SyncErrorClassifier {
  // Private constructor — this class is not meant to be instantiated.
  const SyncErrorClassifier._();

  /// Returns `true` when [error] represents a network-connectivity failure that
  /// should trigger a retry with exponential backoff.
  ///
  /// Checks cover:
  /// - Socket / host-lookup failures
  /// - Connection refused / reset / timed out
  /// - No internet / unreachable network
  /// - Android Cronet errors
  /// - HTTP client exceptions
  /// - Chromium network-change errors
  static bool isNetworkError(dynamic error) {
    if (error is Exception) {
      final String errorStr = error.toString().toLowerCase();
      return errorStr.contains('socketexception') ||
          errorStr.contains('networkexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('connection reset') ||
          errorStr.contains('connection timed out') ||
          errorStr.contains('no internet connection') ||
          errorStr.contains('network is unreachable') ||
          errorStr.contains('err_network_changed') ||
          errorStr.contains('cronet') ||
          errorStr.contains('clientexception');
    }
    // Fallback: inspect string representation for non-Exception objects.
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
        errorStr.contains('networkexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('no internet connection') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('err_network_changed') ||
        errorStr.contains('cronet') ||
        errorStr.contains('clientexception');
  }

  /// Returns `true` when [error] represents a request-timeout condition that
  /// should trigger a retry with exponential backoff.
  ///
  /// Checks cover:
  /// - HTTP 408 (Request Timeout) via a Chopper [Response]
  /// - Dart [TimeoutException] and its string representations
  /// - gRPC / deadline exceeded patterns
  static bool isTimeoutError(dynamic error) {
    if (error is Response && error.statusCode == 408) {
      return true;
    }
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('timeoutexception') ||
        errorStr.contains('timeout') ||
        errorStr.contains('timed out') ||
        errorStr.contains('deadline exceeded');
  }

  /// Returns `true` when [error] represents a server-side failure (5xx) or
  /// rate-limiting (HTTP 429) that should trigger a retry with exponential
  /// backoff.
  static bool isServerError(dynamic error) {
    if (error is Response) {
      return (error.statusCode >= 500 && error.statusCode < 600) ||
          error.statusCode == 429;
    }
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504') ||
        errorStr.contains('429');
  }

  /// Returns `true` when [error] represents an authentication or authorisation
  /// failure (HTTP 401 / 403).
  ///
  /// An auth error from any entity endpoint is treated as a genuine credential
  /// failure because all Firefly III endpoints share the same Bearer token.
  static bool isAuthError(dynamic error) {
    if (error is Response) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('forbidden');
  }

  /// Returns `true` when [error] represents an HTTP 409 Conflict.
  ///
  /// Chopper may surface the status code via:
  /// - A direct [Response] object
  /// - An exception with a `base`, `response`, or `originalResponse` property
  ///   containing a [Response]
  /// - A string representation that includes "409" or "Conflict"
  static bool isConflictError(dynamic error) {
    if (error is Response) {
      return error.statusCode == 409;
    }

    if (error is Exception) {
      final dynamic errorObj = error;

      // Chopper ResponseException — may expose response via 'base'.
      try {
        final dynamic base = (errorObj as dynamic).base;
        if (base is Response && base.statusCode == 409) {
          return true;
        }
      } catch (_) {
        // Property may not exist.
      }

      // Alternative Chopper exception — may expose response via 'response'.
      try {
        final dynamic response = (errorObj as dynamic).response;
        if (response is Response && response.statusCode == 409) {
          return true;
        }
      } catch (_) {
        // Property may not exist.
      }

      // Chopper may also store the response in 'originalResponse'.
      try {
        final dynamic originalResponse = (errorObj as dynamic).originalResponse;
        if (originalResponse is Response &&
            originalResponse.statusCode == 409) {
          return true;
        }
      } catch (_) {
        // Property may not exist.
      }

      // Pattern-match the stringified error.
      final String errorStr = errorObj.toString();
      if (RegExp(r'\b409\b').hasMatch(errorStr)) {
        return true;
      }
      if (errorStr.contains('Conflict') || errorStr.contains('conflict')) {
        return true;
      }
    }

    // Final fallback for non-Exception objects.
    final String errorStr = error.toString();
    return errorStr.contains('409') ||
        errorStr.contains('Conflict') ||
        errorStr.contains('conflict');
  }
}
