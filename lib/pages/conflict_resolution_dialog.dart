import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/conflict.dart';
import '../services/sync/conflict_resolver.dart';

/// Dialog for resolving data conflicts.
///
/// Features:
/// - Side-by-side comparison of local vs remote
/// - Highlight conflicting fields
/// - Display timestamps
/// - Resolution strategy buttons
/// - Preview of resolution result
/// - Material 3 design
class ConflictResolutionDialog extends StatefulWidget {
  final Conflict conflict;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  static final Logger _logger = Logger('ConflictResolutionDialog');

  final ConflictResolver _resolver = ConflictResolver();
  ResolutionStrategy? _selectedStrategy;
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resolve Conflict',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        Text(
                          widget.conflict.entityType,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComparisonSection(),
                    const SizedBox(height: 24),
                    _buildStrategySection(),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isResolving ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedStrategy == null || _isResolving
                        ? null
                        : _resolveConflict,
                    child: _isResolving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conflicting Fields',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVersionCard(
                'Local Version',
                widget.conflict.localData,
                Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildVersionCard(
                'Server Version',
                widget.conflict.remoteData,
                Theme.of(context).colorScheme.tertiaryContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVersionCard(String title, Map<String, dynamic> data, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...widget.conflict.conflictingFields.map((field) {
              final value = data[field];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      value?.toString() ?? 'null',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolution Strategy',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildStrategyButton(
          ResolutionStrategy.localWins,
          'Keep Local Changes',
          'Use your local changes and overwrite server',
          Icons.phone_android,
        ),
        const SizedBox(height: 8),
        _buildStrategyButton(
          ResolutionStrategy.remoteWins,
          'Use Server Version',
          'Discard local changes and use server version',
          Icons.cloud,
        ),
        const SizedBox(height: 8),
        _buildStrategyButton(
          ResolutionStrategy.lastWriteWins,
          'Last Write Wins',
          'Use the most recently modified version',
          Icons.access_time,
        ),
        const SizedBox(height: 8),
        _buildStrategyButton(
          ResolutionStrategy.merge,
          'Merge Both',
          'Combine non-conflicting changes from both versions',
          Icons.merge,
        ),
      ],
    );
  }

  Widget _buildStrategyButton(
    ResolutionStrategy strategy,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedStrategy == strategy;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStrategy = strategy;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveConflict() async {
    if (_selectedStrategy == null) return;

    setState(() {
      _isResolving = true;
    });

    try {
      _logger.info(
        'Resolving conflict ${widget.conflict.id} with strategy $_selectedStrategy',
      );

      await _resolver.resolveConflict(
        widget.conflict,
        _selectedStrategy!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conflict resolved')),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to resolve conflict', e, stackTrace);

      if (mounted) {
        setState(() {
          _isResolving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve: $e')),
        );
      }
    }
  }
}
