/// ETag Response Model
///
/// Wraps API responses with ETag information for HTTP cache validation.
/// ETags (Entity Tags) enable bandwidth-efficient cache validation by allowing
/// the client to send an If-None-Match header with the cached ETag value.
/// If the server data hasn't changed, it returns 304 Not Modified with no body,
/// saving bandwidth.
///
/// HTTP Cache Validation Flow:
/// 1. First request: Server returns 200 with ETag header and full response body
/// 2. Cache stores: response data + ETag value
/// 3. Subsequent request: Client sends If-None-Match: {cached ETag}
/// 4. Server compares: If ETag matches (data unchanged) → 304 Not Modified (no body)
/// 5. Server compares: If ETag differs (data changed) → 200 OK with new data and new ETag
///
/// Bandwidth Savings:
/// - 304 response: ~200 bytes (headers only, no body)
/// - 200 response: 2-50KB+ (full response body)
/// - Typical savings: 90-99% bandwidth reduction for unchanged data
///
/// Architecture Integration:
/// - Used by CacheService to store/retrieve ETags
/// - Used by repositories to pass ETags to API client
/// - Used by API wrapper to extract ETags from response headers
/// - Integrated with stale-while-revalidate pattern
///
/// Example Usage:
/// ```dart
/// // First request (cache miss)
/// final response1 = await apiClient.getAccountWithETag('123');
/// print(response1.statusCode); // 200
/// print(response1.etag); // "abc123def456"
/// print(response1.data); // Account(id: 123, ...)
///
/// // Cache the ETag
/// await cacheService.set(
///   entityType: 'account',
///   entityId: '123',
///   data: response1.data!,
///   etag: response1.etag,
/// );
///
/// // Subsequent request (with cached ETag)
/// final response2 = await apiClient.getAccountWithETag(
///   '123',
///   ifNoneMatch: 'abc123def456',
/// );
/// if (response2.statusCode == 304) {
///   print('Data unchanged, using cached data');
///   // Use cached data, no need to parse response body
/// } else {
///   print('Data changed, updating cache');
///   print(response2.etag); // "xyz789ghi012"
///   print(response2.data); // Account(id: 123, ...) with new data
/// }
/// ```
///
/// ETag Format:
/// ETags can be:
/// - Strong: "abc123" (exact match required)
/// - Weak: W/"abc123" (semantic equivalence, not byte-for-byte)
///
/// This implementation supports both formats.
class ETagResponse<T> {
  /// HTTP status code
  ///
  /// Common values:
  /// - 200: OK (data in body)
  /// - 304: Not Modified (no data, use cached)
  /// - 404: Not Found
  /// - 500: Server Error
  final int statusCode;

  /// Response data (null for 304 Not Modified)
  ///
  /// When statusCode == 304, this is null and cached data should be used.
  /// When statusCode == 200, this contains the parsed response data.
  final T? data;

  /// ETag value from response headers
  ///
  /// Format examples:
  /// - Strong ETag: "abc123def456"
  /// - Weak ETag: W/"abc123def456"
  ///
  /// Null if server doesn't provide ETag header.
  final String? etag;

  /// Whether response was from cache (304 Not Modified)
  ///
  /// True when:
  /// - statusCode == 304
  /// - Server confirmed cached data is still valid
  /// - No response body transmitted (bandwidth saved)
  ///
  /// False when:
  /// - statusCode == 200 (full response)
  /// - First request (no cached ETag)
  /// - Data changed since last request
  final bool isNotModified;

  /// Response headers (for debugging and additional cache directives)
  ///
  /// May include:
  /// - Cache-Control: max-age, no-cache, etc.
  /// - Expires: absolute expiration time
  /// - Last-Modified: last modification timestamp
  /// - Vary: fields that affect caching
  final Map<String, String>? headers;

  /// Creates an ETag response
  ///
  /// Parameters:
  /// - [statusCode]: HTTP status code
  /// - [data]: Response data (null for 304)
  /// - [etag]: ETag value from response header
  /// - [headers]: All response headers
  ///
  /// The [isNotModified] flag is automatically set based on statusCode.
  ///
  /// Example:
  /// ```dart
  /// // 200 OK response with ETag
  /// final response200 = ETagResponse<Account>(
  ///   statusCode: 200,
  ///   data: account,
  ///   etag: "abc123",
  ///   headers: {"cache-control": "max-age=3600"},
  /// );
  ///
  /// // 304 Not Modified response
  /// final response304 = ETagResponse<Account>(
  ///   statusCode: 304,
  ///   data: null, // No data transmitted
  ///   etag: "abc123", // Same ETag
  ///   headers: {"cache-control": "max-age=3600"},
  /// );
  /// ```
  const ETagResponse({
    required this.statusCode,
    this.data,
    this.etag,
    this.headers,
  }) : isNotModified = statusCode == 304;

  /// Creates a successful response (200 OK)
  ///
  /// Factory for common case of successful response with data and ETag.
  ///
  /// Parameters:
  /// - [data]: Response data
  /// - [etag]: ETag value (optional)
  /// - [headers]: Response headers (optional)
  ///
  /// Example:
  /// ```dart
  /// final response = ETagResponse.ok(
  ///   data: account,
  ///   etag: "abc123",
  /// );
  /// ```
  factory ETagResponse.ok({
    required T data,
    String? etag,
    Map<String, String>? headers,
  }) {
    return ETagResponse<T>(
      statusCode: 200,
      data: data,
      etag: etag,
      headers: headers,
    );
  }

  /// Creates a not modified response (304)
  ///
  /// Factory for common case of cache validation success.
  /// Data is null because server doesn't send body for 304.
  ///
  /// Parameters:
  /// - [etag]: ETag value (same as cached)
  /// - [headers]: Response headers (optional)
  ///
  /// Example:
  /// ```dart
  /// final response = ETagResponse<Account>.notModified(
  ///   etag: "abc123",
  /// );
  /// // Use cached data since response.isNotModified == true
  /// ```
  factory ETagResponse.notModified({
    String? etag,
    Map<String, String>? headers,
  }) {
    return ETagResponse<T>(
      statusCode: 304,
      data: null,
      etag: etag,
      headers: headers,
    );
  }

  /// Creates an error response
  ///
  /// Factory for error responses (4xx, 5xx).
  ///
  /// Parameters:
  /// - [statusCode]: HTTP error status code
  /// - [headers]: Response headers (optional)
  ///
  /// Example:
  /// ```dart
  /// final response = ETagResponse<Account>.error(statusCode: 404);
  /// ```
  factory ETagResponse.error({
    required int statusCode,
    Map<String, String>? headers,
  }) {
    return ETagResponse<T>(
      statusCode: statusCode,
      data: null,
      etag: null,
      headers: headers,
    );
  }

  /// Whether response is successful (2xx status code)
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Whether response has data
  bool get hasData => data != null;

  /// Whether response has ETag
  bool get hasETag => etag != null && etag!.isNotEmpty;

  /// Whether ETag is weak (starts with W/)
  bool get isWeakETag => etag?.startsWith('W/') ?? false;

  /// Whether ETag is strong (doesn't start with W/)
  bool get isStrongETag => hasETag && !isWeakETag;

  /// Get normalized ETag (without W/ prefix)
  ///
  /// Removes W/ prefix from weak ETags for storage.
  ///
  /// Example:
  /// ```dart
  /// final response = ETagResponse.ok(data: account, etag: 'W/"abc123"');
  /// print(response.normalizedETag); // "abc123" (without W/)
  /// ```
  String? get normalizedETag {
    if (etag == null) return null;
    if (isWeakETag) {
      return etag!.substring(2); // Remove W/ prefix
    }
    return etag;
  }

  /// Get Cache-Control header value
  String? get cacheControl => headers?['cache-control'] ?? headers?['Cache-Control'];

  /// Get max-age from Cache-Control header (in seconds)
  ///
  /// Parses Cache-Control header to extract max-age directive.
  ///
  /// Example:
  /// ```dart
  /// // Cache-Control: max-age=3600, public
  /// print(response.maxAge); // 3600
  /// ```
  int? get maxAge {
    final cc = cacheControl;
    if (cc == null) return null;

    // Parse: max-age=3600
    final regex = RegExp(r'max-age=(\d+)');
    final match = regex.firstMatch(cc);
    if (match == null) return null;

    return int.tryParse(match.group(1)!);
  }

  /// Whether response has no-cache directive
  bool get hasNoCache {
    final cc = cacheControl;
    return cc?.contains('no-cache') ?? false;
  }

  /// Whether response has no-store directive (don't cache at all)
  bool get hasNoStore {
    final cc = cacheControl;
    return cc?.contains('no-store') ?? false;
  }

  /// Whether response is cacheable
  ///
  /// Response is cacheable if:
  /// - Successful (2xx or 304)
  /// - No no-store directive
  /// - Has ETag or max-age
  bool get isCacheable {
    if (!isSuccessful && !isNotModified) return false;
    if (hasNoStore) return false;
    return hasETag || maxAge != null;
  }

  /// Convert to map for logging/debugging
  ///
  /// Example:
  /// ```dart
  /// final map = response.toMap();
  /// print(map);
  /// // {statusCode: 200, hasData: true, etag: "abc123", isNotModified: false}
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'statusCode': statusCode,
      'hasData': hasData,
      'etag': etag,
      'isNotModified': isNotModified,
      'isSuccessful': isSuccessful,
      'hasETag': hasETag,
      'isCacheable': isCacheable,
      'maxAge': maxAge,
      'cacheControl': cacheControl,
    };
  }

  /// Convert to string for logging
  @override
  String toString() {
    return 'ETagResponse<$T>(statusCode: $statusCode, '
        'hasData: $hasData, etag: $etag, isNotModified: $isNotModified)';
  }

  /// Copy with modifications
  ///
  /// Creates a new ETagResponse with specified fields replaced.
  ///
  /// Example:
  /// ```dart
  /// final response2 = response1.copyWith(statusCode: 304);
  /// ```
  ETagResponse<T> copyWith({
    int? statusCode,
    T? data,
    String? etag,
    Map<String, String>? headers,
  }) {
    return ETagResponse<T>(
      statusCode: statusCode ?? this.statusCode,
      data: data ?? this.data,
      etag: etag ?? this.etag,
      headers: headers ?? this.headers,
    );
  }
}
