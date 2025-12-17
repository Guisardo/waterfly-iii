import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/sync/sync_progress_tracker.dart';
import 'package:waterflyiii/models/sync_progress.dart';

void main() {
  group('SyncProgressTracker', () {
    late SyncProgressTracker tracker;

    setUp(() {
      tracker = SyncProgressTracker();
    });

    tearDown(() {
      tracker.dispose();
    });

    group('start', () {
      test('initializes progress tracking', () {
        tracker.start(totalOperations: 100);

        expect(tracker.isInProgress, true);
        expect(tracker.currentProgress, isNotNull);
        expect(tracker.currentProgress!.totalOperations, 100);
        expect(tracker.currentProgress!.completedOperations, 0);
        expect(tracker.currentProgress!.percentage, 0.0);
        expect(tracker.currentProgress!.phase, SyncPhase.preparing);
      });

      test('emits started event', () async {
        final List<SyncEvent> events = <SyncEvent>[];
        tracker.watchEvents().listen(events.add);

        tracker.start(totalOperations: 50);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<SyncStartedEvent>());
        expect((events.first as SyncStartedEvent).totalOperations, 50);
      });

      test('emits initial progress', () async {
        final List<SyncProgress> progressUpdates = <SyncProgress>[];
        tracker.watchProgress().listen(progressUpdates.add);

        tracker.start(totalOperations: 100);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(progressUpdates, hasLength(1));
        expect(progressUpdates.first.totalOperations, 100);
      });
    });

    group('updatePhase', () {
      test('updates current phase', () {
        tracker.start(totalOperations: 100);

        tracker.updatePhase(SyncPhase.syncing);

        expect(tracker.currentProgress!.phase, SyncPhase.syncing);
      });

      test('emits progress update', () async {
        final List<SyncProgress> progressUpdates = <SyncProgress>[];
        tracker.watchProgress().listen(progressUpdates.add);

        tracker.start(totalOperations: 100);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.updatePhase(SyncPhase.syncing);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(progressUpdates.length, greaterThan(1));
        expect(progressUpdates.last.phase, SyncPhase.syncing);
      });
    });

    group('incrementCompleted', () {
      test('increments completed count', () {
        tracker.start(totalOperations: 100);

        tracker.incrementCompleted();
        tracker.incrementCompleted();

        expect(tracker.currentProgress!.completedOperations, 2);
      });

      test('updates percentage', () {
        tracker.start(totalOperations: 100);

        tracker.incrementCompleted();

        expect(tracker.currentProgress!.percentage, 1.0);

        for (int i = 0; i < 49; i++) {
          tracker.incrementCompleted();
        }

        expect(tracker.currentProgress!.percentage, 50.0);
      });

      test('calculates throughput', () async {
        tracker.start(totalOperations: 100);

        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 10));
          tracker.incrementCompleted();
        }

        expect(tracker.currentProgress!.throughput, greaterThan(0));
      });

      test('estimates time remaining', () async {
        tracker.start(totalOperations: 100);

        // Complete some operations to establish throughput
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 10));
          tracker.incrementCompleted();
        }

        // ETA should be calculated
        expect(tracker.currentProgress!.estimatedTimeRemaining, isNotNull);
      });
    });

    group('incrementFailed', () {
      test('increments failed count', () {
        tracker.start(totalOperations: 100);

        tracker.incrementFailed(error: 'Error 1');
        tracker.incrementFailed(error: 'Error 2');

        expect(tracker.currentProgress!.failedOperations, 2);
        expect(tracker.currentProgress!.errors, hasLength(2));
      });

      test('updates percentage including failed', () {
        tracker.start(totalOperations: 100);

        tracker.incrementCompleted();
        tracker.incrementFailed();

        // 2 processed out of 100 = 2%
        expect(tracker.currentProgress!.percentage, 2.0);
      });
    });

    group('incrementSkipped', () {
      test('increments skipped count', () {
        tracker.start(totalOperations: 100);

        tracker.incrementSkipped();
        tracker.incrementSkipped();

        expect(tracker.currentProgress!.skippedOperations, 2);
      });
    });

    group('incrementConflicts', () {
      test('increments conflicts count', () {
        tracker.start(totalOperations: 100);

        tracker.incrementConflicts();
        tracker.incrementConflicts();

        expect(tracker.currentProgress!.conflictsDetected, 2);
      });

      test('emits conflict detected event', () async {
        final List<SyncEvent> events = <SyncEvent>[];
        tracker.watchEvents().listen(events.add);

        tracker.start(totalOperations: 100);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.incrementConflicts(conflictId: 'conflict_1');
        await Future.delayed(const Duration(milliseconds: 10));

        final List<ConflictDetectedEvent> conflictEvents =
            events.whereType<ConflictDetectedEvent>().toList();
        expect(conflictEvents, hasLength(1));
        expect(conflictEvents.first.conflict, 'conflict_1');
      });
    });

    group('addCompleted', () {
      test('adds multiple completed at once', () {
        tracker.start(totalOperations: 100);

        tracker.addCompleted(10);

        expect(tracker.currentProgress!.completedOperations, 10);
        expect(tracker.currentProgress!.percentage, 10.0);
      });
    });

    group('complete', () {
      test('completes tracking successfully', () {
        tracker.start(totalOperations: 100);

        for (int i = 0; i < 80; i++) {
          tracker.incrementCompleted();
        }
        for (int i = 0; i < 10; i++) {
          tracker.incrementFailed();
        }
        for (int i = 0; i < 10; i++) {
          tracker.incrementSkipped();
        }

        final SyncResult result = tracker.complete(success: true);

        expect(result.success, true);
        expect(result.totalOperations, 100);
        expect(result.successfulOperations, 80);
        expect(result.failedOperations, 10);
        expect(result.skippedOperations, 10);
        expect(result.successRate, 0.8); // 80/(80+10)
        expect(tracker.isInProgress, false);
      });

      test('emits completed event', () async {
        final List<SyncEvent> events = <SyncEvent>[];
        tracker.watchEvents().listen(events.add);

        tracker.start(totalOperations: 10);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.complete(success: true);
        await Future.delayed(const Duration(milliseconds: 10));

        final List<SyncCompletedEvent> completedEvents =
            events.whereType<SyncCompletedEvent>().toList();
        expect(completedEvents, hasLength(1));
        expect(completedEvents.first.result.success, true);
      });

      test('emits failed event on failure', () async {
        final List<SyncEvent> events = <SyncEvent>[];
        tracker.watchEvents().listen(events.add);

        tracker.start(totalOperations: 10);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.complete(success: false);
        await Future.delayed(const Duration(milliseconds: 10));

        final List<SyncFailedEvent> failedEvents =
            events.whereType<SyncFailedEvent>().toList();
        expect(failedEvents, hasLength(1));
      });

      test('calculates duration', () {
        tracker.start(totalOperations: 10);

        // Simulate some work
        for (int i = 0; i < 10; i++) {
          tracker.incrementCompleted();
        }

        final SyncResult result = tracker.complete(success: true);

        expect(result.duration, greaterThan(Duration.zero));
      });

      test('throws if no sync in progress', () {
        expect(() => tracker.complete(success: true), throwsStateError);
      });
    });

    group('cancel', () {
      test('cancels current sync', () {
        tracker.start(totalOperations: 100);

        tracker.cancel();

        expect(tracker.isInProgress, false);
      });

      test('emits failed event', () async {
        final List<SyncEvent> events = <SyncEvent>[];
        tracker.watchEvents().listen(events.add);

        tracker.start(totalOperations: 100);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.cancel();
        await Future.delayed(const Duration(milliseconds: 10));

        final List<SyncFailedEvent> failedEvents =
            events.whereType<SyncFailedEvent>().toList();
        expect(failedEvents, hasLength(1));
        expect(failedEvents.first.error, contains('cancelled'));
      });
    });

    group('progress calculation', () {
      test('calculates percentage correctly', () {
        tracker.start(totalOperations: 100);

        tracker.addCompleted(25);
        expect(tracker.currentProgress!.percentage, 25.0);

        tracker.addCompleted(25);
        expect(tracker.currentProgress!.percentage, 50.0);

        tracker.addCompleted(50);
        expect(tracker.currentProgress!.percentage, 100.0);
      });

      test('handles zero total operations', () {
        tracker.start(totalOperations: 0);

        expect(tracker.currentProgress!.percentage, 0.0);
      });

      test('calculates success rate correctly', () {
        tracker.start(totalOperations: 100);

        for (int i = 0; i < 80; i++) {
          tracker.incrementCompleted();
        }
        for (int i = 0; i < 20; i++) {
          tracker.incrementFailed();
        }

        final SyncResult result = tracker.complete(success: true);

        expect(result.successRate, 0.8);
      });

      test('handles zero operations for success rate', () {
        tracker.start(totalOperations: 100);

        final SyncResult result = tracker.complete(success: true);

        expect(result.successRate, 0.0);
      });
    });

    group('stream behavior', () {
      test('progress stream emits updates', () async {
        final List<SyncProgress> progressUpdates = <SyncProgress>[];
        tracker.watchProgress().listen(progressUpdates.add);

        tracker.start(totalOperations: 10);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.incrementCompleted();
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.incrementCompleted();
        await Future.delayed(const Duration(milliseconds: 10));

        expect(progressUpdates.length, greaterThanOrEqualTo(3));
      });

      test('event stream emits all event types', () async {
        final List<SyncEvent> events = <SyncEvent>[];
        tracker.watchEvents().listen(events.add);

        tracker.start(totalOperations: 10);
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.incrementConflicts(conflictId: 'c1');
        await Future.delayed(const Duration(milliseconds: 10));

        tracker.complete(success: true);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.whereType<SyncStartedEvent>(), hasLength(1));
        expect(events.whereType<ConflictDetectedEvent>(), hasLength(1));
        expect(events.whereType<SyncCompletedEvent>(), hasLength(1));
      });
    });
  });
}
