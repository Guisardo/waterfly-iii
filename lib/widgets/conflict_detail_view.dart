import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/conflict.dart';

/// Detailed view of a conflict showing full entity details.
///
/// Features:
/// - Show full entity details for both versions
/// - Expandable cards for each field
/// - Highlight differences with color
/// - Field-by-field selection for merge
/// - Show metadata (who changed, when)
/// - Material 3 design
class ConflictDetailView extends StatefulWidget {
  final Conflict conflict;
  final Function(Map<String, dynamic>)? onMergeSelectionChanged;

  const ConflictDetailView({
    super.key,
    required this.conflict,
    this.onMergeSelectionChanged,
  });

  @override
  State<ConflictDetailView> createState() => _ConflictDetailViewState();
}

class _ConflictDetailViewState extends State<ConflictDetailView> {
  static final Logger _logger = Logger('ConflictDetailView');

  final Map<String, String> _mergeSelection = {}; // field -> 'local' or 'remote'
  final Set<String> _expandedFields = {};

  @override
  void initState() {
    super.initState();
    // Initialize merge selection with local values by default
    for (final field in widget.conflict.conflictingFields) {
      _mergeSelection[field] = 'local';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetadataSection(),
        const SizedBox(height: 16),
        _buildFieldsSection(),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conflict Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Type', widget.conflict.conflictType.toString().split('.').last),
            _buildMetadataRow('Severity', widget.conflict.severity.toString().split('.').last),
            _buildMetadataRow('Detected', _formatDateTime(widget.conflict.detectedAt)),
            _buildMetadataRow('Conflicting Fields', widget.conflict.conflictingFields.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
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

  Widget _buildFieldsSection() {
    final allFields = <String>{
      ...widget.conflict.localData.keys,
      ...widget.conflict.remoteData.keys,
    }.toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Comparison',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...allFields.map((field) => _buildFieldCard(field)),
      ],
    );
  }

  Widget _buildFieldCard(String field) {
    final isConflicting = widget.conflict.conflictingFields.contains(field);
    final isExpanded = _expandedFields.contains(field);
    final localValue = widget.conflict.localData[field];
    final remoteValue = widget.conflict.remoteData[field];
    final selectedSource = _mergeSelection[field];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isConflicting
          ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3)
          : null,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isConflicting ? Icons.warning_amber : Icons.check_circle_outline,
              color: isConflicting
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
            ),
            title: Text(
              field,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: isConflicting
                ? Text(
                    'Values differ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : const Text('Values match'),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  if (isExpanded) {
                    _expandedFields.remove(field);
                  } else {
                    _expandedFields.add(field);
                  }
                });
              },
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildValueComparison(
                    'Local',
                    localValue,
                    isConflicting && selectedSource == 'local',
                    () {
                      if (isConflicting) {
                        setState(() {
                          _mergeSelection[field] = 'local';
                        });
                        _notifyMergeSelectionChanged();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildValueComparison(
                    'Remote',
                    remoteValue,
                    isConflicting && selectedSource == 'remote',
                    () {
                      if (isConflicting) {
                        setState(() {
                          _mergeSelection[field] = 'remote';
                        });
                        _notifyMergeSelectionChanged();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValueComparison(
    String source,
    dynamic value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatValue(value),
                    style: Theme.of(context).textTheme.bodyMedium,
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

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) return _formatDateTime(value);
    if (value is Map) return 'Object (${value.length} fields)';
    if (value is List) return 'Array (${value.length} items)';
    return value.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _notifyMergeSelectionChanged() {
    if (widget.onMergeSelectionChanged == null) return;

    final mergedData = <String, dynamic>{};

    // Start with all local data
    mergedData.addAll(widget.conflict.localData);

    // Override with selected remote values
    for (final entry in _mergeSelection.entries) {
      if (entry.value == 'remote') {
        mergedData[entry.key] = widget.conflict.remoteData[entry.key];
      }
    }

    widget.onMergeSelectionChanged!(mergedData);
    _logger.fine('Merge selection changed: ${_mergeSelection.length} fields selected');
  }
}
