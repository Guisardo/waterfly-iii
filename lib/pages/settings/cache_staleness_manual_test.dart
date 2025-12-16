import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:waterflyiii/services/cache/cache_service.dart';

/// Manual Test Page for Cache Staleness Detection
///
/// This page provides a manual testing interface to verify TTL-based staleness
/// detection works correctly in a real app environment, overcoming the
/// limitations of the automated test framework.
///
/// **Purpose**: Automated widget tests hang when calling CacheService.isFresh()
/// during widget loading (async DB queries conflict with test framework).
/// This manual test page proves the functionality works in production.
///
/// **Test Scenario**:
/// 1. Cache data with short TTL (10 seconds)
/// 2. Display countdown timer showing time until stale
/// 3. Verify staleness indicator appears when TTL expires
/// 4. Verify background refresh updates cache metadata
/// 5. Verify UI reflects cache freshness state
///
/// **How to Use**:
/// 1. Enable debug mode in app settings
/// 2. Navigate to: Settings → Debug → Cache Staleness Test
/// 3. Tap "Start Test" to cache test data with 10-second TTL
/// 4. Observe countdown timer (10 → 0 seconds)
/// 5. When timer reaches 0, staleness indicator should appear
/// 6. Check logs for detailed staleness detection info
/// 7. Tap "Force Stale" to immediately expire cache for quick testing
/// 8. Tap "Refresh" to trigger background refresh
///
/// **Expected Behavior**:
/// - Fresh data: Green indicator, no refresh icon
/// - Stale data: Orange indicator, refresh icon shown
/// - Countdown shows time until cache becomes stale
/// - Logs show detailed freshness check operations
///
/// **Log Monitoring**:
/// Enable verbose logging to see staleness detection:
/// - Logger.root.level = Level.ALL (in main.dart)
/// - Look for [STALENESS CHECK] log messages
/// - Verify isFresh() calls and results
///
/// See: test/manual/cache_staleness_manual_test.md for complete test procedure
class CacheStalenessManualTestPage extends StatefulWidget {
  const CacheStalenessManualTestPage({super.key});

  @override
  State<CacheStalenessManualTestPage> createState() =>
      _CacheStalenessManualTestPageState();
}

class _CacheStalenessManualTestPageState
    extends State<CacheStalenessManualTestPage> {
  final Logger _log = Logger('CacheStalenessManualTest');

  // Test data
  static const String testEntityType = 'manual_test_entity';
  static const String testEntityId = 'test_001';
  static const Duration testTtl = Duration(seconds: 10);

  // Test state
  bool _testRunning = false;
  bool _cacheExists = false;
  bool _isFresh = false;
  DateTime? _cachedAt;
  DateTime? _expiresAt;
  int _secondsUntilStale = 0;
  String _testData = '';

  // Timer for countdown
  Timer? _countdownTimer;

  // Logs
  final List<String> _logMessages = [];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Start the staleness detection test
  Future<void> _startTest() async {
    _addLog('=== STARTING STALENESS DETECTION TEST ===');
    _addLog('Entity: $testEntityType:$testEntityId');
    _addLog('TTL: ${testTtl.inSeconds} seconds');

    setState(() {
      _testRunning = true;
      _logMessages.clear();
    });

    try {
      final cacheService = context.read<CacheService>();

      // Clear any existing cache for this test entity
      _addLog('Clearing existing cache...');
      await cacheService.invalidate(testEntityType, testEntityId);
      await Future.delayed(Duration(milliseconds: 100));

      // Cache test data with short TTL
      final testData = 'Test Data - ${DateTime.now().toIso8601String()}';
      _addLog('Caching test data: $testData');
      _addLog('TTL: ${testTtl.inSeconds} seconds');

      await cacheService.set(
        entityType: testEntityType,
        entityId: testEntityId,
        data: testData,
        ttl: testTtl,
      );

      _addLog('✅ Test data cached successfully');
      _testData = testData;
      _cachedAt = DateTime.now(); // Track when data was cached locally

      // Start monitoring cache freshness
      await _checkFreshness();
      _startCountdownTimer();

      _addLog('📊 Monitoring cache freshness...');
      _addLog('⏱️  Countdown started');
    } catch (e, stackTrace) {
      _addLog('❌ ERROR: $e');
      _log.severe('Test failed', e, stackTrace);
      setState(() {
        _testRunning = false;
      });
    }
  }

  /// Check cache freshness and update UI
  Future<void> _checkFreshness() async {
    if (!mounted) return;

    try {
      final cacheService = context.read<CacheService>();

      // Check if cache exists and is fresh using public API
      final isFresh =
          await cacheService.isFresh(testEntityType, testEntityId);

      // Calculate time remaining based on local tracking
      // (Avoids direct database access which can fail on some devices)
      if (mounted) {
        setState(() {
          _cacheExists = _cachedAt != null;
          _isFresh = isFresh;

          if (_cachedAt != null) {
            _expiresAt = _cachedAt!.add(testTtl);
            _secondsUntilStale = _expiresAt!.difference(DateTime.now()).inSeconds;
            if (_secondsUntilStale < 0) _secondsUntilStale = 0;
          }
        });
      }

      _addLog(
        '🔍 Freshness check: ${isFresh ? "FRESH ✅" : "STALE ⚠️"} '
        '(${_secondsUntilStale}s remaining)',
      );
    } catch (e) {
      _addLog('❌ Freshness check error: $e');
    }
  }

  /// Start countdown timer
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      await _checkFreshness();

      // Stop timer when stale
      if (_secondsUntilStale <= 0 && !_isFresh) {
        _addLog('⏱️  COUNTDOWN COMPLETE - Cache is now STALE ⚠️');
        timer.cancel();
      }
    });
  }

  /// Force cache to become stale immediately
  Future<void> _forceStale() async {
    _addLog('⚡ Forcing cache to become stale...');

    try {
      final cacheService = context.read<CacheService>();

      // Re-cache with 1ms TTL (will be stale immediately)
      await cacheService.set(
        entityType: testEntityType,
        entityId: testEntityId,
        data: _testData,
        ttl: Duration(milliseconds: 1),
      );

      await Future.delayed(Duration(milliseconds: 50));

      // Update local tracking to reflect stale state
      _cachedAt = DateTime.now().subtract(testTtl).subtract(Duration(seconds: 1));
      
      _addLog('✅ Cache forced to stale state');
      await _checkFreshness();
    } catch (e) {
      _addLog('❌ Error forcing stale: $e');
    }
  }

  /// Trigger background refresh
  Future<void> _triggerRefresh() async {
    _addLog('🔄 Triggering background refresh...');

    try {
      final cacheService = context.read<CacheService>();

      // Simulate background refresh by re-caching with fresh TTL
      final newData = 'Refreshed Data - ${DateTime.now().toIso8601String()}';
      await cacheService.set(
        entityType: testEntityType,
        entityId: testEntityId,
        data: newData,
        ttl: testTtl,
      );

      _testData = newData;
      _cachedAt = DateTime.now(); // Update local tracking

      _addLog('✅ Background refresh complete');
      _addLog('📦 New data: $newData');

      await _checkFreshness();
      _startCountdownTimer(); // Restart countdown with new TTL
    } catch (e) {
      _addLog('❌ Refresh error: $e');
    }
  }

  /// Clear test cache
  Future<void> _clearTest() async {
    _addLog('🗑️  Clearing test cache...');

    try {
      final cacheService = context.read<CacheService>();
      await cacheService.invalidate(testEntityType, testEntityId);

      _countdownTimer?.cancel();

      setState(() {
        _testRunning = false;
        _cacheExists = false;
        _isFresh = false;
        _cachedAt = null;
        _expiresAt = null;
        _secondsUntilStale = 0;
        _testData = '';
      });

      _addLog('✅ Test cache cleared');
      _addLog('=== TEST COMPLETE ===');
    } catch (e) {
      _addLog('❌ Clear error: $e');
    }
  }

  /// Add log message
  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1];
    final logMessage = '[$timestamp] $message';

    setState(() {
      _logMessages.add(logMessage);
    });

    _log.info(message);

    // Keep only last 50 messages
    if (_logMessages.length > 50) {
      _logMessages.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Staleness Manual Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Manual Test Instructions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Tap "Start Test" to cache data with 10-second TTL\n'
                      '2. Watch countdown timer (10 → 0 seconds)\n'
                      '3. Verify staleness indicator appears at 0 seconds\n'
                      '4. Check logs for detailed freshness detection\n'
                      '5. Use "Force Stale" for quick testing\n'
                      '6. Use "Refresh" to verify cache updates',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _testRunning ? null : _startTest,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Test'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testRunning ? _forceStale : null,
                          icon: const Icon(Icons.fast_forward),
                          label: const Text('Force Stale'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testRunning ? _triggerRefresh : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _testRunning ? _clearTest : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Clear Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.errorContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cache Status Display
            if (_testRunning) ...[
              Card(
                color: _isFresh
                    ? Colors.green.shade50
                    : _cacheExists
                        ? Colors.orange.shade50
                        : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isFresh ? Icons.check_circle : Icons.refresh,
                            color: _isFresh ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isFresh ? 'FRESH ✅' : 'STALE ⚠️',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: _isFresh
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isFresh
                                      ? 'Cache is fresh and valid'
                                      : 'Cache has exceeded TTL',
                                  style: TextStyle(
                                    color: _isFresh
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Countdown',
                        '$_secondsUntilStale seconds',
                        Icons.timer,
                      ),
                      _buildInfoRow(
                        'Cached At',
                        _cachedAt?.toString().split('.')[0] ?? 'N/A',
                        Icons.access_time,
                      ),
                      _buildInfoRow(
                        'Expires At',
                        _expiresAt?.toString().split('.')[0] ?? 'N/A',
                        Icons.event,
                      ),
                      _buildInfoRow(
                        'TTL',
                        '${testTtl.inSeconds} seconds',
                        Icons.schedule,
                      ),
                      const Divider(height: 24),
                      Text(
                        'Test Data:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _testData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Log Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Test Logs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          iconSize: 20,
                          onPressed: () {
                            setState(() {
                              _logMessages.clear();
                            });
                          },
                          tooltip: 'Clear logs',
                        ),
                      ],
                    ),
                    const Divider(),
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _logMessages.isEmpty
                          ? const Center(
                              child: Text(
                                'No logs yet. Start the test to see logs.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              itemCount: _logMessages.length,
                              itemBuilder: (context, index) {
                                final message =
                                    _logMessages[_logMessages.length - 1 - index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
