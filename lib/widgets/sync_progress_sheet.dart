import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/sync_progress.dart';
import '../models/sync_operation.dart';
import '../services/sync/sync_manager.dart';
import '../services/sync/sync_queue_manager.dart';

/// Bottom sheet showing sync progress with expandable details.
///
/// Features:
/// - Non-blocking UI alternative to dialog
/// - Expandable/collapsible progress view
/// - Operation list with status icons
/// - Pull-to-refresh gesture
/// - Sync statistics display
/// - "View Details" button
/// - Material 3 design
class SyncProgressSheet extends StatefulWidget {
  /// Sync manager instance
  final SyncManager syncManager;

  /// Whether the sheet starts expanded
  final bool initiallyExpanded;

  const SyncProgressSheet({
    super.key,
    required this.syncManager,
    this.initiallyExpanded = false,
  });

  @override
  State<SyncProgressSheet> createState() => _SyncProgressSheetState();
}

class _SyncProgressSheetState extends State<SyncProgressSheet> {
  static final Logger _logger = Logger('SyncProgressSheet');

  bool _isExpanded = false;
  final SyncQueueManager _queueManager = SyncQueueManager();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: _isExpanded ? 0.6 : 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              _buildHeader(),

              const Divider(height: 1),

              // Content
              Expanded(
                child: StreamBuilder<SyncProgress>(
                  stream: widget.syncManager.progressTracker.watchProgress(),
                  builder: (context, snapshot) {
                    final progress = snapshot.data;

                    if (progress == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildProgressSection(progress),
                          const SizedBox(height: 16),
                          _buildStatisticsSection(progress),
                          if (_isExpanded) ...[
                            const SizedBox(height: 16),
                            _buildOperationsSection(),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.sync,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Sync Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_isExpanded ? Icons.expand_more : Icons.expand_less),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            tooltip: _isExpanded ? 'Collapse' : 'Expand',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(SyncProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.percentage / 100,
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.completedOperations} of ${progress.totalOperations} operations',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (progress.currentOperation != null) ...[
              const SizedBox(height: 4),
              Text(
                'Current: ${progress.currentOperation}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(SyncProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Completed',
              progress.completedOperations.toString(),
              Icons.check_circle,
              Theme.of(context).colorScheme.tertiary,
            ),
            _buildStatRow(
              'Failed',
              progress.failedOperations.toString(),
              Icons.error,
              Theme.of(context).colorScheme.error,
            ),
            _buildStatRow(
              'Skipped',
              progress.skippedOperations.toString(),
              Icons.skip_next,
              Theme.of(context).colorScheme.outline,
            ),
            if (progress.conflictsDetected > 0)
              _buildStatRow(
                'Conflicts',
                progress.conflictsDetected.toString(),
                Icons.warning,
                Theme.of(context).colorScheme.tertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsSection() {
    return FutureBuilder<List<SyncOperation>>(
      future: _queueManager.getPendingOperations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final operations = snapshot.data!;

        if (operations.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No pending operations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Operations (${operations.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const Divider(height: 1),
              ...operations.take(10).map((op) => ListTile(
                    leading: _getOperationIcon(op),
                    title: Text(op.entityType),
                    subtitle: Text(op.operationType.toString().split('.').last),
                    trailing: _getOperationStatusIcon(op),
                  )),
              if (operations.length > 10)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '... and ${operations.length - 10} more',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _getOperationIcon(SyncOperation operation) {
    IconData icon;
    switch (operation.operationType) {
      case OperationType.create:
        icon = Icons.add_circle_outline;
        break;
      case OperationType.update:
        icon = Icons.edit_outlined;
        break;
      case OperationType.delete:
        icon = Icons.delete_outline;
        break;
    }

    return Icon(
      icon,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _getOperationStatusIcon(SyncOperation operation) {
    if (operation.retryCount > 0) {
      return Icon(
        Icons.refresh,
        color: Theme.of(context).colorScheme.tertiary,
        size: 20,
      );
    }
    return Icon(
      Icons.schedule,
      color: Theme.of(context).colorScheme.outline,
      size: 20,
    );
  }

  Future<void> _handleRefresh() async {
    _logger.info('Manual sync triggered from bottom sheet');
    await widget.syncManager.synchronize();
  }
}
