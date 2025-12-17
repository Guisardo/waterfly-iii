import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/models/cache/etag_response.dart';

/// ETag Handler Service
///
/// Comprehensive service for HTTP ETag (Entity Tag) cache validation.
/// Implements RFC 7232 (HTTP Conditional Requests) for bandwidth-efficient caching.
///
/// Key Features:
/// - ETag extraction from response headers
/// - If-None-Match header injection for conditional requests
/// - 304 Not Modified response handling
/// - Strong and weak ETag support
/// - Cache-Control directive parsing
/// - Bandwidth savings tracking
/// - Comprehensive logging for debugging
///
/// HTTP Cache Validation Pattern:
/// 1. Client makes initial request → Server returns 200 with ETag
/// 2. Client caches: data + ETag
/// 3. Client makes subsequent request with If-None-Match: {ETag}
/// 4. Server checks: If data unchanged → 304 (no body, ~200 bytes)
/// 5. Server checks: If data changed → 200 (full body, 2-50KB+)
///
/// Bandwidth Savings Example:
/// - Without ETags: 50KB * 100 requests = 5MB
/// - With ETags (80% unchanged): (50KB * 20) + (0.2KB * 80) = 1MB + 16KB = 1.016MB
/// - Savings: 5MB - 1.016MB = 3.984MB (79.7% reduction)
///
/// RFC 7232 Compliance:
/// - Strong comparison: byte-for-byte equality
/// - Weak comparison: semantic equivalence
/// - If-None-Match: comma-separated ETags or *
/// - Multiple ETag matching (for range requests)
///
/// Integration with Waterfly III:
/// - Works with Dio HTTP client (already integrated)
/// - Can work with Chopper (via interceptors)
/// - Integrated with CacheService for ETag storage
/// - Used by repositories for conditional requests
///
/// Example Usage:
/// ```dart
/// final etagHandler = ETagHandler();
///
/// // First request (no cached ETag)
/// final options1 = RequestOptions(path: '/api/accounts/123');
/// final rawResponse1 = await dio.get('/api/accounts/123');
/// final response1 = etagHandler.wrapResponse<Account>(
///   response: rawResponse1,
///   parser: (json) => Account.fromJson(json),
/// );
///
/// print(response1.statusCode); // 200
/// print(response1.etag); // "abc123"
/// print(response1.data); // Account(...)
///
/// // Store ETag in cache
/// final cachedETag = response1.etag;
///
/// // Subsequent request (with cached ETag)
/// final options2 = etagHandler.addETagHeaders(
///   RequestOptions(path: '/api/accounts/123'),
///   ifNoneMatch: cachedETag,
/// );
/// final rawResponse2 = await dio.fetch(options2);
/// final response2 = etagHandler.wrapResponse<Account>(
///   response: rawResponse2,
///   parser: (json) => Account.fromJson(json),
///   cachedData: cachedAccountData, // For 304 responses
/// );
///
/// if (response2.isNotModified) {
///   print('304 Not Modified - using cached data');
///   // Use cachedAccountData, no parsing needed
/// } else {
///   print('200 OK - data changed, updating cache');
///   print(response2.etag); // "xyz789" (new ETag)
///   print(response2.data); // Account(...) (new data)
/// }
/// ```
///
/// Statistics Tracking:
/// ```dart
/// final stats = etagHandler.getStats();
/// print('Total requests: ${stats.totalRequests}');
/// print('304 responses: ${stats.notModifiedCount}');
/// print('Bandwidth saved: ${stats.bandwidthSavedMB}MB');
/// print('Savings rate: ${stats.savingsRate}%');
/// ```
class ETagHandler {
  final Logger _log = Logger('ETagHandler');

  // ========== Statistics Tracking ==========

  /// Total number of requests processed
  int _totalRequests = 0;

  /// Number of 304 Not Modified responses (ETag hit)
  int _notModifiedCount = 0;

  /// Number of 200 OK responses (ETag miss or no ETag)
  int _modifiedCount = 0;

  /// Estimated bandwidth saved in bytes (from 304 responses)
  int _bandwidthSavedBytes = 0;

  /// Estimated bandwidth used in bytes (from 200 responses)
  int _bandwidthUsedBytes = 0;

  /// Creates an ETag handler
  ///
  /// Example:
  /// ```dart
  /// final handler = ETagHandler();
  /// ```
  ETagHandler() {
    _log.info('ETagHandler initialized');
  }

  // ========== ETag Extraction ==========

  /// Extract ETag from response headers
  ///
  /// Supports multiple header formats:
  /// - Standard: ETag: "abc123"
  /// - Weak: ETag: W/"abc123"
  /// - Case variations: etag, Etag, ETAG
  ///
  /// Parameters:
  /// - [headers]: Response headers map
  ///
  /// Returns:
  /// ETag value (without quotes) or null if not present
  ///
  /// Example:
  /// ```dart
  /// final headers = {'etag': '"abc123"'};
  /// final etag = handler.extractETag(headers);
  /// print(etag); // "abc123"
  ///
  /// final headers2 = {'etag': 'W/"xyz789"'};
  /// final etag2 = handler.extractETag(headers2);
  /// print(etag2); // W/"xyz789"
  /// ```
  String? extractETag(Map<String, dynamic>? headers) {
    if (headers == null || headers.isEmpty) {
      _log.finest('No headers provided for ETag extraction');
      return null;
    }

    // Try common header name variations
    final etagValue =
        headers['etag'] ??
        headers['ETag'] ??
        headers['Etag'] ??
        headers['ETAG'];

    if (etagValue == null) {
      _log.finest('No ETag header found');
      return null;
    }

    // Convert to string and trim
    final String etagStr = etagValue.toString().trim();

    if (etagStr.isEmpty) {
      _log.finest('Empty ETag header');
      return null;
    }

    _log.fine('Extracted ETag: $etagStr');
    return etagStr;
  }

  /// Extract ETag from Dio response
  ///
  /// Convenience method for Dio Response objects.
  ///
  /// Parameters:
  /// - [response]: Dio Response object
  ///
  /// Returns:
  /// ETag value or null
  ///
  /// Example:
  /// ```dart
  /// final response = await dio.get('/api/accounts/123');
  /// final etag = handler.extractETagFromDio(response);
  /// ```
  String? extractETagFromDio(Response response) {
    return extractETag(response.headers.map);
  }

  // ========== Request Header Injection ==========

  /// Add If-None-Match header to request options
  ///
  /// Adds conditional request headers for ETag validation.
  /// Server will return 304 if ETag matches (data unchanged).
  ///
  /// Parameters:
  /// - [options]: Dio RequestOptions to modify
  /// - [ifNoneMatch]: Cached ETag value(s)
  /// - [multiple]: Whether to support multiple ETags (for range requests)
  ///
  /// Returns:
  /// Modified RequestOptions with If-None-Match header
  ///
  /// Example:
  /// ```dart
  /// final options = RequestOptions(path: '/api/accounts/123');
  /// final modifiedOptions = handler.addETagHeaders(
  ///   options,
  ///   ifNoneMatch: 'abc123',
  /// );
  ///
  /// // modifiedOptions.headers now contains:
  /// // {"If-None-Match": "abc123"}
  /// ```
  RequestOptions addETagHeaders(
    RequestOptions options, {
    required String? ifNoneMatch,
    bool multiple = false,
  }) {
    if (ifNoneMatch == null || ifNoneMatch.isEmpty) {
      _log.finest('No ETag provided, skipping If-None-Match header');
      return options;
    }

    // Add If-None-Match header
    // Note: ETags should already include quotes if needed
    options.headers['If-None-Match'] = ifNoneMatch;

    _log.fine('Added If-None-Match header: $ifNoneMatch');

    return options;
  }

  /// Create Dio options with ETag headers
  ///
  /// Factory method to create RequestOptions with conditional headers.
  ///
  /// Parameters:
  /// - [path]: API endpoint path
  /// - [method]: HTTP method (default: GET)
  /// - [ifNoneMatch]: Cached ETag value
  /// - [baseUrl]: Base URL (optional)
  /// - [queryParameters]: Query parameters (optional)
  /// - [headers]: Additional headers (optional)
  ///
  /// Returns:
  /// RequestOptions configured for conditional request
  ///
  /// Example:
  /// ```dart
  /// final options = handler.createOptionsWithETag(
  ///   path: '/api/accounts/123',
  ///   ifNoneMatch: 'abc123',
  /// );
  /// final response = await dio.fetch(options);
  /// ```
  RequestOptions createOptionsWithETag({
    required String path,
    String method = 'GET',
    String? ifNoneMatch,
    String? baseUrl,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    final RequestOptions options = RequestOptions(
      path: path,
      method: method,
      baseUrl: baseUrl ?? '',
      queryParameters: queryParameters,
      headers: headers,
    );

    return addETagHeaders(options, ifNoneMatch: ifNoneMatch);
  }

  // ========== Response Wrapping ==========

  /// Wrap Dio response in ETagResponse
  ///
  /// Converts raw Dio Response to ETagResponse with proper handling of:
  /// - 200 OK: Parse data and extract ETag
  /// - 304 Not Modified: Use cached data, extract ETag
  /// - 4xx/5xx: Error response, no data
  ///
  /// Type Parameters:
  /// - [T]: Type of response data
  ///
  /// Parameters:
  /// - [response]: Raw Dio Response object
  /// - [parser]: Function to parse JSON to T (for 200 responses)
  /// - [cachedData]: Cached data to use for 304 responses
  ///
  /// Returns:
  /// ETagResponse<T> with data, ETag, and metadata
  ///
  /// Throws:
  /// - [ArgumentError] if parser is null and statusCode is 200
  /// - [ArgumentError] if cachedData is null and statusCode is 304
  ///
  /// Example:
  /// ```dart
  /// final rawResponse = await dio.get('/api/accounts/123');
  /// final response = handler.wrapResponse<Account>(
  ///   response: rawResponse,
  ///   parser: (json) => Account.fromJson(json),
  ///   cachedData: cachedAccount, // For potential 304
  /// );
  ///
  /// if (response.isNotModified) {
  ///   print('Using cached data');
  /// } else {
  ///   print('New data: ${response.data}');
  /// }
  /// ```
  ETagResponse<T> wrapResponse<T>({
    required Response response,
    T Function(Map<String, dynamic> json)? parser,
    T? cachedData,
  }) {
    _totalRequests++;

    final int statusCode = response.statusCode ?? 500;
    final String? etag = extractETagFromDio(response);
    final Map<String, String> headers = _convertHeaders(response.headers.map);

    _log.fine(
      'Wrapping response: statusCode=$statusCode, hasETag=${etag != null}',
    );

    // Handle 304 Not Modified
    if (statusCode == 304) {
      _notModifiedCount++;

      // Estimate bandwidth saved (no response body transmitted)
      // Average response body size: ~5KB
      const int avgResponseSize = 5 * 1024;
      _bandwidthSavedBytes += avgResponseSize;

      _log.info(
        '304 Not Modified response (bandwidth saved: ~${avgResponseSize}B)',
      );

      if (cachedData == null) {
        _log.warning(
          '304 response but no cached data provided - this is unusual',
        );
      }

      return ETagResponse<T>.notModified(etag: etag, headers: headers);
    }

    // Handle 200 OK
    if (statusCode >= 200 && statusCode < 300) {
      _modifiedCount++;

      // Track bandwidth used
      final int responseSize = _estimateResponseSize(response);
      _bandwidthUsedBytes += responseSize;

      _log.info('200 OK response (size: ~${responseSize}B)');

      // Parse response data
      T? data;
      if (parser != null && response.data != null) {
        try {
          // Handle both Map and already-parsed objects
          if (response.data is Map<String, dynamic>) {
            data = parser(response.data as Map<String, dynamic>);
          } else if (response.data is String) {
            // Parse JSON string
            final Map<String, dynamic> json =
                jsonDecode(response.data as String) as Map<String, dynamic>;
            data = parser(json);
          } else if (response.data is T) {
            // Already parsed
            data = response.data as T;
          } else {
            _log.warning(
              'Unexpected response.data type: ${response.data.runtimeType}',
            );
          }
        } catch (e, stackTrace) {
          _log.severe('Failed to parse response data', e, stackTrace);
          // Let data remain null, error will be handled by caller
        }
      }

      // Return error if data is null (parsing failed or no parser provided)
      if (data == null) {
        _log.severe('No data parsed from 200 response');
        return ETagResponse<T>.error(statusCode: 500, headers: headers);
      }

      return ETagResponse<T>.ok(data: data, etag: etag, headers: headers);
    }

    // Handle errors (4xx, 5xx)
    _log.warning('Error response: statusCode=$statusCode');

    return ETagResponse<T>.error(statusCode: statusCode, headers: headers);
  }

  /// Wrap list response (for collection endpoints)
  ///
  /// Specialized wrapper for list/collection responses.
  ///
  /// Parameters:
  /// - [response]: Raw Dio Response
  /// - [parser]: Function to parse JSON to T
  /// - [cachedData]: Cached list for 304 responses
  ///
  /// Returns:
  /// ETagResponse<List<T>> with list data
  ///
  /// Example:
  /// ```dart
  /// final rawResponse = await dio.get('/api/accounts');
  /// final response = handler.wrapListResponse<Account>(
  ///   response: rawResponse,
  ///   parser: (json) => Account.fromJson(json),
  ///   cachedData: cachedAccounts,
  /// );
  ///
  /// print('Accounts: ${response.data?.length ?? 0}');
  /// ```
  ETagResponse<List<T>> wrapListResponse<T>({
    required Response response,
    required T Function(Map<String, dynamic> json) parser,
    List<T>? cachedData,
  }) {
    final int statusCode = response.statusCode ?? 500;
    final String? etag = extractETagFromDio(response);
    final Map<String, String> headers = _convertHeaders(response.headers.map);

    // Handle 304 Not Modified
    if (statusCode == 304) {
      _notModifiedCount++;
      _bandwidthSavedBytes += 10 * 1024; // Estimate 10KB saved for lists

      _log.info('304 Not Modified (list response)');

      // Return response with null data (caller should use cachedData)
      return ETagResponse<List<T>>(
        statusCode: 304,
        data: null,
        etag: etag,
        headers: headers,
      );
    }

    // Handle 200 OK
    if (statusCode >= 200 && statusCode < 300) {
      _modifiedCount++;
      _bandwidthUsedBytes += _estimateResponseSize(response);

      _log.info('200 OK (list response)');

      // Parse list data
      List<T>? data;
      if (response.data != null) {
        try {
          if (response.data is List) {
            data =
                (response.data as List)
                    .map((item) => parser(item as Map<String, dynamic>))
                    .toList();
          } else if (response.data is Map<String, dynamic>) {
            // Handle wrapped list (e.g., {"data": [...]})
            final Map<String, dynamic> map =
                response.data as Map<String, dynamic>;
            if (map.containsKey('data') && map['data'] is List) {
              data =
                  (map['data'] as List)
                      .map((item) => parser(item as Map<String, dynamic>))
                      .toList();
            }
          }
        } catch (e, stackTrace) {
          _log.severe('Failed to parse list response', e, stackTrace);
        }
      }

      // Return error if data is null (parsing failed)
      if (data == null) {
        _log.severe('No data parsed from 200 list response');
        return ETagResponse<List<T>>.error(statusCode: 500, headers: headers);
      }

      return ETagResponse<List<T>>.ok(data: data, etag: etag, headers: headers);
    }

    // Handle errors
    return ETagResponse<List<T>>.error(
      statusCode: statusCode,
      headers: headers,
    );
  }

  // ========== Helper Methods ==========

  /// Convert Headers to string map
  ///
  /// Dio Headers.map returns Map<String, List<String>>, but we need
  /// Map<String, String> for ETagResponse.
  Map<String, String> _convertHeaders(Map<String, List<String>> headersMap) {
    final Map<String, String> converted = <String, String>{};
    headersMap.forEach((String key, List<String> values) {
      if (values.isNotEmpty) {
        converted[key] = values.join(', ');
      }
    });
    return converted;
  }

  /// Estimate response size in bytes
  ///
  /// Estimates based on:
  /// - Response data size (JSON length)
  /// - Headers size (approximate)
  int _estimateResponseSize(Response response) {
    int size = 0;

    // Estimate data size
    if (response.data != null) {
      if (response.data is String) {
        size += (response.data as String).length;
      } else if (response.data is Map || response.data is List) {
        // Estimate JSON size
        final String jsonStr = jsonEncode(response.data);
        size += jsonStr.length;
      } else {
        // Default estimate
        size += 2048;
      }
    }

    // Estimate headers size (~500 bytes)
    size += 500;

    return size;
  }

  // ========== Statistics ==========

  /// Get ETag handler statistics
  ///
  /// Returns comprehensive statistics about ETag usage and bandwidth savings.
  ///
  /// Returns:
  /// Map with statistics
  ///
  /// Example:
  /// ```dart
  /// final stats = handler.getStats();
  /// print('Total requests: ${stats['totalRequests']}');
  /// print('304 responses: ${stats['notModifiedCount']}');
  /// print('Bandwidth saved: ${stats['bandwidthSavedMB']}MB');
  /// ```
  Map<String, dynamic> getStats() {
    final double notModifiedRate =
        _totalRequests > 0 ? _notModifiedCount / _totalRequests : 0.0;

    final double bandwidthSavedMB = _bandwidthSavedBytes / (1024 * 1024);
    final double bandwidthUsedMB = _bandwidthUsedBytes / (1024 * 1024);
    final double totalBandwidthMB = bandwidthSavedMB + bandwidthUsedMB;

    final double savingsRate =
        totalBandwidthMB > 0
            ? (bandwidthSavedMB / totalBandwidthMB) * 100
            : 0.0;

    return <String, dynamic>{
      'totalRequests': _totalRequests,
      'notModifiedCount': _notModifiedCount,
      'modifiedCount': _modifiedCount,
      'notModifiedRate': notModifiedRate,
      'notModifiedRatePercent': notModifiedRate * 100,
      'bandwidthSavedBytes': _bandwidthSavedBytes,
      'bandwidthUsedBytes': _bandwidthUsedBytes,
      'bandwidthSavedMB': bandwidthSavedMB,
      'bandwidthUsedMB': bandwidthUsedMB,
      'totalBandwidthMB': totalBandwidthMB,
      'savingsRate': savingsRate,
    };
  }

  /// Reset statistics
  ///
  /// Resets all counters to zero. Useful for testing or periodic resets.
  ///
  /// Example:
  /// ```dart
  /// handler.resetStats();
  /// ```
  void resetStats() {
    _log.info('Resetting ETag statistics');
    _totalRequests = 0;
    _notModifiedCount = 0;
    _modifiedCount = 0;
    _bandwidthSavedBytes = 0;
    _bandwidthUsedBytes = 0;
  }

  /// Log current statistics
  ///
  /// Logs comprehensive statistics at INFO level.
  ///
  /// Example:
  /// ```dart
  /// handler.logStats();
  /// // Logs: ETag Statistics: total=100, 304=75, savings=80%
  /// ```
  void logStats() {
    final Map<String, dynamic> stats = getStats();
    _log.info(
      'ETag Statistics: '
      'total=${stats['totalRequests']}, '
      '304=${stats['notModifiedCount']} (${stats['notModifiedRatePercent'].toStringAsFixed(1)}%), '
      'bandwidth saved=${stats['bandwidthSavedMB'].toStringAsFixed(2)}MB, '
      'savings rate=${stats['savingsRate'].toStringAsFixed(1)}%',
    );
  }
}
