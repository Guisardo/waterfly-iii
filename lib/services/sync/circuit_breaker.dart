import 'dart:async';
import 'package:logging/logging.dart';
import 'package:synchronized/synchronized.dart';

import 'package:waterflyiii/exceptions/sync_exceptions.dart';

/// Circuit breaker states
enum CircuitState {
  /// Circuit is closed, requests flow normally
  closed,

  /// Circuit is open, requests are rejected
  open,

  /// Circuit is half-open, testing if service recovered
  halfOpen,
}

/// Circuit breaker for protecting API from cascading failures.
///
/// Implements the circuit breaker pattern to prevent overwhelming a failing
/// service with requests. The circuit has three states:
/// - CLOSED: Normal operation, requests pass through
/// - OPEN: Service is failing, requests are rejected immediately
/// - HALF_OPEN: Testing if service recovered, limited requests allowed
///
/// Example:
/// ```dart
/// final breaker = CircuitBreaker(
///   failureThreshold: 5,
///   resetTimeout: Duration(seconds: 60),
/// );
///
/// try {
///   final result = await breaker.execute(
///     () => apiClient.getData(),
///     operationName: 'get_data',
///   );
/// } on CircuitBreakerOpenError {
///   // Handle circuit open
/// }
/// ```
class CircuitBreaker {
  final Logger _logger = Logger('CircuitBreaker');

  /// Lock for thread-safe state management
  final Lock _lock = Lock();

  /// Current circuit state
  CircuitState _state = CircuitState.closed;

  /// Number of consecutive failures
  int _failureCount = 0;

  /// Number of consecutive successes in half-open state
  int _successCount = 0;

  /// Timestamp of last failure
  DateTime? _lastFailureTime;

  /// Timestamp when circuit was opened
  DateTime? _openedAt;

  /// Configuration

  /// Number of consecutive failures before opening circuit
  final int failureThreshold;

  /// Number of successes needed to close circuit from half-open
  final int successThreshold;

  /// Time to wait before attempting to close circuit
  final Duration resetTimeout;

  /// Timeout for individual operations
  final Duration operationTimeout;

  /// Statistics

  /// Total successful operations
  int _totalSuccesses = 0;

  /// Total failed operations
  int _totalFailures = 0;

  /// Total rejected operations (circuit open)
  int _totalRejected = 0;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.successThreshold = 2,
    this.resetTimeout = const Duration(seconds: 60),
    this.operationTimeout = const Duration(seconds: 30),
  });

  /// Execute an operation through the circuit breaker.
  ///
  /// Args:
  ///   operation: The async operation to execute
  ///   operationName: Name for logging purposes
  ///
  /// Returns:
  ///   Result of the operation
  ///
  /// Throws:
  ///   CircuitBreakerOpenError: If circuit is open
  ///   TimeoutError: If operation times out
  ///   Original exception if operation fails
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    final String name = operationName ?? 'operation';

    return _lock.synchronized(() async {
      // Check if circuit should transition to half-open
      _checkStateTransition();

      // Reject if circuit is open
      if (_state == CircuitState.open) {
        _totalRejected++;
        _logger.warning(
          'Circuit is OPEN, rejecting $name '
          '(failures: $_failureCount, opened: ${_openedAt?.toIso8601String()})',
        );
        throw CircuitBreakerOpenError(
          'Circuit breaker is open, operation rejected',
          failureCount: _failureCount,
          resetTime: _openedAt!.add(resetTimeout),
        );
      }

      // Execute operation with timeout
      try {
        _logger.fine(
          'Executing $name through circuit breaker (state: $_state)',
        );

        final T result = await operation().timeout(
          operationTimeout,
          onTimeout: () {
            throw TimeoutError(
              'Operation $name timed out after ${operationTimeout.inSeconds}s',
              timeout: operationTimeout,
            );
          },
        );

        // Record success
        await _recordSuccess(name);

        return result;
      } catch (e, stackTrace) {
        // Record failure
        await _recordFailure(name, e, stackTrace);
        rethrow;
      }
    });
  }

  /// Record a successful operation.
  Future<void> _recordSuccess(String operationName) async {
    _totalSuccesses++;
    _failureCount = 0;
    _lastFailureTime = null;

    if (_state == CircuitState.halfOpen) {
      _successCount++;
      _logger.fine(
        'Success in HALF_OPEN state for $operationName '
        '($_successCount/$successThreshold)',
      );

      if (_successCount >= successThreshold) {
        _transitionToClosed();
      }
    } else {
      _logger.fine('Success for $operationName (state: $_state)');
    }
  }

  /// Record a failed operation.
  Future<void> _recordFailure(
    String operationName,
    Object error,
    StackTrace stackTrace,
  ) async {
    _totalFailures++;
    _failureCount++;
    _successCount = 0;
    _lastFailureTime = DateTime.now();

    _logger.warning(
      'Failure for $operationName: $error '
      '(consecutive failures: $_failureCount/$failureThreshold)',
    );

    // Open circuit if threshold reached
    if (_failureCount >= failureThreshold) {
      _transitionToOpen();
    }
  }

  /// Check if circuit should transition from open to half-open.
  void _checkStateTransition() {
    if (_state == CircuitState.open && _openedAt != null) {
      final Duration timeSinceOpen = DateTime.now().difference(_openedAt!);

      if (timeSinceOpen >= resetTimeout) {
        _transitionToHalfOpen();
      }
    }
  }

  /// Transition circuit to CLOSED state.
  void _transitionToClosed() {
    _logger.info(
      'Circuit breaker transitioning to CLOSED '
      '(successes: $_successCount/$successThreshold)',
    );

    _state = CircuitState.closed;
    _failureCount = 0;
    _successCount = 0;
    _openedAt = null;
  }

  /// Transition circuit to OPEN state.
  void _transitionToOpen() {
    _logger.warning(
      'Circuit breaker transitioning to OPEN '
      '(failures: $_failureCount/$failureThreshold)',
    );

    _state = CircuitState.open;
    _openedAt = DateTime.now();
    _successCount = 0;
  }

  /// Transition circuit to HALF_OPEN state.
  void _transitionToHalfOpen() {
    _logger.info(
      'Circuit breaker transitioning to HALF_OPEN '
      '(reset timeout elapsed: ${resetTimeout.inSeconds}s)',
    );

    _state = CircuitState.halfOpen;
    _successCount = 0;
  }

  /// Manually reset the circuit breaker to CLOSED state.
  Future<void> reset() async {
    await _lock.synchronized(() {
      _logger.info('Manually resetting circuit breaker to CLOSED');

      _state = CircuitState.closed;
      _failureCount = 0;
      _successCount = 0;
      _lastFailureTime = null;
      _openedAt = null;
    });
  }

  /// Manually open the circuit breaker.
  Future<void> open() async {
    await _lock.synchronized(() {
      _logger.warning('Manually opening circuit breaker');
      _transitionToOpen();
    });
  }

  /// Get current circuit state.
  CircuitState get state => _state;

  /// Check if circuit is open.
  bool get isOpen => _state == CircuitState.open;

  /// Check if circuit is closed.
  bool get isClosed => _state == CircuitState.closed;

  /// Check if circuit is half-open.
  bool get isHalfOpen => _state == CircuitState.halfOpen;

  /// Get circuit breaker statistics.
  CircuitBreakerStatistics getStatistics() {
    return CircuitBreakerStatistics(
      state: _state,
      totalSuccesses: _totalSuccesses,
      totalFailures: _totalFailures,
      totalRejected: _totalRejected,
      consecutiveFailures: _failureCount,
      consecutiveSuccesses: _successCount,
      lastFailureTime: _lastFailureTime,
      openedAt: _openedAt,
      successRate: _calculateSuccessRate(),
      rejectionRate: _calculateRejectionRate(),
    );
  }

  /// Calculate success rate.
  double _calculateSuccessRate() {
    final int total = _totalSuccesses + _totalFailures;
    return total > 0 ? _totalSuccesses / total : 0.0;
  }

  /// Calculate rejection rate.
  double _calculateRejectionRate() {
    final int total = _totalSuccesses + _totalFailures + _totalRejected;
    return total > 0 ? _totalRejected / total : 0.0;
  }

  /// Reset statistics.
  Future<void> resetStatistics() async {
    await _lock.synchronized(() {
      _logger.info('Resetting circuit breaker statistics');

      _totalSuccesses = 0;
      _totalFailures = 0;
      _totalRejected = 0;
    });
  }

  @override
  String toString() {
    return 'CircuitBreaker('
        'state: $_state, '
        'failures: $_failureCount/$failureThreshold, '
        'successes: $_totalSuccesses, '
        'rejected: $_totalRejected'
        ')';
  }
}

/// Circuit breaker statistics.
class CircuitBreakerStatistics {
  /// Current circuit state
  final CircuitState state;

  /// Total successful operations
  final int totalSuccesses;

  /// Total failed operations
  final int totalFailures;

  /// Total rejected operations
  final int totalRejected;

  /// Consecutive failures
  final int consecutiveFailures;

  /// Consecutive successes (in half-open state)
  final int consecutiveSuccesses;

  /// Timestamp of last failure
  final DateTime? lastFailureTime;

  /// Timestamp when circuit was opened
  final DateTime? openedAt;

  /// Success rate (0.0 to 1.0)
  final double successRate;

  /// Rejection rate (0.0 to 1.0)
  final double rejectionRate;

  const CircuitBreakerStatistics({
    required this.state,
    required this.totalSuccesses,
    required this.totalFailures,
    required this.totalRejected,
    required this.consecutiveFailures,
    required this.consecutiveSuccesses,
    this.lastFailureTime,
    this.openedAt,
    required this.successRate,
    required this.rejectionRate,
  });

  /// Total operations attempted
  int get totalOperations => totalSuccesses + totalFailures + totalRejected;

  @override
  String toString() {
    return 'CircuitBreakerStatistics('
        'state: $state, '
        'total: $totalOperations, '
        'successes: $totalSuccesses, '
        'failures: $totalFailures, '
        'rejected: $totalRejected, '
        'success_rate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'rejection_rate: ${(rejectionRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}
