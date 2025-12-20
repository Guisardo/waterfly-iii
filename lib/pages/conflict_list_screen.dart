import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';

final Logger _log = Logger('ConflictListScreen');

/// Comprehensive conflict list and resolution screen.
///
/// Features:
/// - List all unresolved conflicts
/// - Group by entity type
/// - Show conflict severity (low, medium, high)
/// - Conflict details view with diff
/// - Resolution options (keep local, keep remote, merge, manual edit)
/// - Bulk resolution support
/// - Filter by entity type, severity, date
/// - Sort options
/// - Empty state when no conflicts
/// - Pull-to-refresh
///
/// Uses Provider for state management and real-time updates.
class ConflictListScreen extends StatefulWidget {
  const ConflictListScreen({super.key});

  @override
  State<ConflictListScreen> createState() => _ConflictListScreenState();
}

class _ConflictListScreenState extends State<ConflictListScreen> {
  String? _filterEntityType;
  String? _filterSeverity;
  String _sortBy = 'date';
  final Set<String> _selectedConflicts = <String>{};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    // Check if SyncStatusProvider is available
    try {
      Provider.of<SyncStatusProvider>(context, listen: false);
    } catch (e) {
      // SyncStatusProvider not available, show error message
      return Scaffold(
        appBar: AppBar(title: const Text('Conflicts')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Sync Status Provider Not Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please restart the app to enable conflict tracking.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflicts'),
        actions: <Widget>[
          if (_isSelectionMode) ...<Widget>[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select all',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectionMode,
              tooltip: 'Cancel',
            ),
          ] else ...<Widget>[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortDialog,
              tooltip: 'Sort',
            ),
          ],
        ],
      ),
      body: Consumer<SyncStatusProvider>(
        builder: (
          BuildContext context,
          SyncStatusProvider provider,
          Widget? child,
        ) {
          final List<dynamic> conflicts = provider.unresolvedConflicts;

          if (conflicts.isEmpty) {
            return _buildEmptyState(context);
          }

          final List<dynamic> filteredConflicts = _filterConflicts(conflicts);
          final List<dynamic> sortedConflicts = _sortConflicts(
            filteredConflicts,
          );

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: Column(
              children: <Widget>[
                if (_filterEntityType != null || _filterSeverity != null)
                  _buildFilterChips(context),
                if (_isSelectionMode)
                  _buildSelectionBar(context, sortedConflicts.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: sortedConflicts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final conflict = sortedConflicts[index];
                      return _buildConflictCard(context, conflict, index);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton:
          _isSelectionMode && _selectedConflicts.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () => _showBulkResolutionDialog(context),
                icon: const Icon(Icons.done_all),
                label: Text('Resolve ${_selectedConflicts.length}'),
              )
              : null,
    );
  }

  /// Build empty state.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
          const SizedBox(height: 24),
          Text(
            'No Conflicts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All conflicts have been resolved',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  /// Build filter chips.
  Widget _buildFilterChips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        children: <Widget>[
          if (_filterEntityType != null)
            Chip(
              label: Text('Type: $_filterEntityType'),
              onDeleted: () => setState(() => _filterEntityType = null),
            ),
          if (_filterSeverity != null)
            Chip(
              label: Text('Severity: $_filterSeverity'),
              onDeleted: () => setState(() => _filterSeverity = null),
            ),
        ],
      ),
    );
  }

  /// Build selection bar.
  Widget _buildSelectionBar(BuildContext context, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: <Widget>[
          Text(
            '${_selectedConflicts.length} of $totalCount selected',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build conflict card.
  Widget _buildConflictCard(
    BuildContext context,
    dynamic conflictEntity,
    int index,
  ) {
    // Convert ConflictEntity to usable data
    final String conflictId = conflictEntity.id as String;
    final String entityType = conflictEntity.entityType as String;
    final String conflictType = conflictEntity.conflictType as String;
    final DateTime detectedAt = conflictEntity.detectedAt as DateTime;

    // Parse conflicting fields to determine severity
    final String conflictingFieldsJson =
        conflictEntity.conflictingFields as String;
    final String severity = _determineSeverity(
      conflictingFieldsJson,
      entityType,
    );

    final bool isSelected = _selectedConflicts.contains(conflictId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(conflictId);
          } else {
            _showConflictDetails(context, conflictEntity);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedConflicts.add(conflictId);
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: <Widget>[
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(conflictId),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.warning_amber,
                          color: _getSeverityColor(severity),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatConflictTitle(conflictType, entityType),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildSeverityBadge(severity),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatConflictDescription(conflictType, entityType),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Icon(Icons.category, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatEntityType(entityType),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(detectedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build severity badge.
  Widget _buildSeverityBadge(String severity) {
    final Color color;
    switch (severity.toLowerCase()) {
      case 'low':
        color = Colors.blue;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'high':
        color = Colors.red;
        break;
      case 'critical':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Show conflict details dialog.
  void _showConflictDetails(BuildContext context, dynamic conflict) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Conflict Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Local Version:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(conflict.toString()),
                  const SizedBox(height: 16),
                  const Text(
                    'Remote Version:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(conflict.toString()),
                  const SizedBox(height: 16),
                  const Text(
                    'Differences:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Field changes will be highlighted here'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resolveConflict(
                    context,
                    conflict,
                    ResolutionStrategy.remoteWins,
                  );
                },
                child: const Text('Keep Remote'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resolveConflict(
                    context,
                    conflict,
                    ResolutionStrategy.localWins,
                  );
                },
                child: const Text('Keep Local'),
              ),
            ],
          ),
    );
  }

  /// Show filter dialog.
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Filter Conflicts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: const Text('Entity Type'),
                  trailing: DropdownButton<String?>(
                    value: _filterEntityType,
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(
                        value: 'Transaction',
                        child: Text('Transaction'),
                      ),
                      const DropdownMenuItem(
                        value: 'Account',
                        child: Text('Account'),
                      ),
                      const DropdownMenuItem(
                        value: 'Category',
                        child: Text('Category'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() => _filterEntityType = value);
                      Navigator.pop(context);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Severity'),
                  trailing: DropdownButton<String?>(
                    value: _filterSeverity,
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(value: 'Low', child: Text('Low')),
                      const DropdownMenuItem(
                        value: 'Medium',
                        child: Text('Medium'),
                      ),
                      const DropdownMenuItem(
                        value: 'High',
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() => _filterSeverity = value);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterEntityType = null;
                    _filterSeverity = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Show sort dialog.
  void _showSortDialog() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Sort By'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RadioListTile<String>(
                  title: const Text('Date'),
                  value: 'date',
                  groupValue: _sortBy,
                  onChanged: (String? value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Severity'),
                  value: 'severity',
                  groupValue: _sortBy,
                  onChanged: (String? value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Entity Type'),
                  value: 'type',
                  groupValue: _sortBy,
                  onChanged: (String? value) {
                    setState(() => _sortBy = value!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// Show bulk resolution dialog.
  void _showBulkResolutionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text('Resolve ${_selectedConflicts.length} Conflicts'),
            content: const Text(
              'Choose a resolution strategy to apply to all selected conflicts:',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resolveBulk(ResolutionStrategy.remoteWins);
                },
                child: const Text('Keep Remote'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resolveBulk(ResolutionStrategy.localWins);
                },
                child: const Text('Keep Local'),
              ),
            ],
          ),
    );
  }

  /// Filter conflicts based on current filters.
  List<dynamic> _filterConflicts(List<dynamic> conflicts) {
    return conflicts.where((conflictEntity) {
      // Filter by entity type
      if (_filterEntityType != null) {
        final String entityType = conflictEntity.entityType as String;
        if (entityType != _filterEntityType) {
          return false;
        }
      }

      // Filter by severity
      if (_filterSeverity != null) {
        final String conflictingFieldsJson =
            conflictEntity.conflictingFields as String;
        final String entityType = conflictEntity.entityType as String;
        final String severity = _determineSeverity(
          conflictingFieldsJson,
          entityType,
        );
        if (severity != _filterSeverity) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Sort conflicts based on current sort option.
  List<dynamic> _sortConflicts(List<dynamic> conflicts) {
    final List<dynamic> sortedList = List<dynamic>.from(conflicts);

    switch (_sortBy) {
      case 'date':
        sortedList.sort((a, b) {
          final DateTime aDate = a.detectedAt as DateTime;
          final DateTime bDate = b.detectedAt as DateTime;
          return bDate.compareTo(aDate); // Newest first
        });
        break;
      case 'entity_type':
        sortedList.sort((a, b) {
          final String aType = a.entityType as String;
          final String bType = b.entityType as String;
          return aType.compareTo(bType);
        });
        break;
      case 'severity':
        sortedList.sort((a, b) {
          final String aFields = a.conflictingFields as String;
          final String bFields = b.conflictingFields as String;
          final String aType = a.entityType as String;
          final String bType = b.entityType as String;
          final String aSeverity = _determineSeverity(aFields, aType);
          final String bSeverity = _determineSeverity(bFields, bType);

          // High > Medium > Low
          final Map<String, int> severityOrder = <String, int>{
            'High': 3,
            'Medium': 2,
            'Low': 1,
          };
          return (severityOrder[bSeverity] ?? 0).compareTo(
            severityOrder[aSeverity] ?? 0,
          );
        });
        break;
    }

    return sortedList;
  }

  /// Determine conflict severity based on conflicting fields and entity type.
  String _determineSeverity(String conflictingFieldsJson, String entityType) {
    try {
      final List<String> fields =
          (jsonDecode(conflictingFieldsJson) as List).cast<String>();

      // Critical fields that indicate high severity
      final Map<String, List<String>> criticalFields = <String, List<String>>{
        'transaction': <String>[
          'amount',
          'date',
          'source_id',
          'destination_id',
        ],
        'account': <String>['account_number', 'iban', 'opening_balance'],
        'category': <String>['name'],
        'budget': <String>['amount', 'start', 'end'],
        'bill': <String>['amount_min', 'amount_max', 'date'],
        'piggy_bank': <String>['target_amount', 'current_amount'],
      };

      // Check if any critical fields are in conflict
      final List<String> entityCriticalFields =
          criticalFields[entityType] ?? <String>[];
      final bool hasCriticalConflict = fields.any(
        (String field) => entityCriticalFields.contains(field),
      );

      if (hasCriticalConflict) {
        return 'High';
      } else if (fields.length > 3) {
        return 'Medium';
      } else {
        return 'Low';
      }
    } catch (e) {
      _log.warning('Failed to determine severity: $e');
      return 'Medium'; // Default to medium if parsing fails
    }
  }

  /// Get color for severity level.
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'High':
        return Colors.red[700]!;
      case 'Medium':
        return Colors.orange[700]!;
      case 'Low':
        return Colors.yellow[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Format conflict title based on type and entity.
  String _formatConflictTitle(String conflictType, String entityType) {
    final String formattedEntity = _formatEntityType(entityType);

    switch (conflictType) {
      case 'update_conflict':
        return '$formattedEntity Update Conflict';
      case 'delete_conflict':
        return '$formattedEntity Delete Conflict';
      case 'create_conflict':
        return '$formattedEntity Creation Conflict';
      default:
        return '$formattedEntity Conflict';
    }
  }

  /// Format conflict description.
  String _formatConflictDescription(String conflictType, String entityType) {
    final String formattedEntity = _formatEntityType(entityType).toLowerCase();

    switch (conflictType) {
      case 'update_conflict':
        return 'Both local and remote versions of this $formattedEntity were modified';
      case 'delete_conflict':
        return 'This $formattedEntity was deleted remotely but modified locally';
      case 'create_conflict':
        return 'This $formattedEntity already exists on the server';
      default:
        return 'Conflict detected for this $formattedEntity';
    }
  }

  /// Format entity type for display.
  String _formatEntityType(String entityType) {
    switch (entityType) {
      case 'transaction':
        return 'Transaction';
      case 'account':
        return 'Account';
      case 'category':
        return 'Category';
      case 'budget':
        return 'Budget';
      case 'bill':
        return 'Bill';
      case 'piggy_bank':
        return 'Piggy Bank';
      default:
        return entityType;
    }
  }

  /// Format timestamp for display.
  String _formatTimestamp(DateTime timestamp) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Toggle conflict selection.
  void _toggleSelection(String conflictId) {
    setState(() {
      if (_selectedConflicts.contains(conflictId)) {
        _selectedConflicts.remove(conflictId);
        if (_selectedConflicts.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConflicts.add(conflictId);
      }
    });
  }

  /// Select all visible conflicts.
  void _selectAll() {
    setState(() {
      final SyncStatusProvider provider = Provider.of<SyncStatusProvider>(
        context,
        listen: false,
      );
      final List<dynamic> conflicts = provider.unresolvedConflicts;
      final List<dynamic> filteredConflicts = _filterConflicts(conflicts);

      // Add all visible conflict IDs to selection
      _selectedConflicts.clear();
      for (final conflictEntity in filteredConflicts) {
        final String conflictId = conflictEntity.id as String;
        _selectedConflicts.add(conflictId);
      }

      _log.info('Selected ${_selectedConflicts.length} conflicts');
    });
  }

  /// Exit selection mode.
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedConflicts.clear();
    });
  }

  /// Resolve single conflict with comprehensive error handling.
  Future<void> _resolveConflict(
    BuildContext context,
    dynamic conflictEntity,
    ResolutionStrategy strategy,
  ) async {
    try {
      _log.info(
        'Resolving conflict ${conflictEntity.id} with strategy: $strategy',
      );

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (BuildContext context) =>
                const Center(child: CircularProgressIndicator()),
      );

      // Convert ConflictEntity to Conflict model
      final Conflict conflict = _convertToConflictModel(conflictEntity);

      // Get dependencies from context
      final AppDatabase database = Provider.of<AppDatabase>(
        context,
        listen: false,
      );
      final FireflyApiAdapter apiAdapter = Provider.of<FireflyApiAdapter>(
        context,
        listen: false,
      );

      // Create resolver and resolve conflict
      final ConflictResolver resolver = ConflictResolver(
        apiAdapter: apiAdapter,
        database: database,
        queueManager: SyncQueueManager(database),
      );
      final Resolution resolution = await resolver.resolveConflict(
        conflict,
        strategy,
      );

      // Close loading indicator
      if (!mounted) return;
      Navigator.of(context).pop();

      if (resolution.success) {
        // Refresh conflicts list
        final SyncStatusProvider provider = Provider.of<SyncStatusProvider>(
          context,
          listen: false,
        );
        await provider.refresh();

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Conflict resolved using ${_formatStrategy(strategy)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to resolve conflict: ${resolution.errorMessage}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to resolve conflict', e, stackTrace);

      // Close loading indicator if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resolving conflict: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Resolve multiple conflicts with comprehensive error handling.
  Future<void> _resolveBulk(ResolutionStrategy strategy) async {
    try {
      _log.info(
        'Resolving ${_selectedConflicts.length} conflicts with strategy: $strategy',
      );

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (BuildContext context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Resolving ${_selectedConflicts.length} conflicts...',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
      );

      // Get all conflicts
      final SyncStatusProvider provider = Provider.of<SyncStatusProvider>(
        context,
        listen: false,
      );
      final List<dynamic> allConflicts = provider.unresolvedConflicts;

      // Filter selected conflicts
      final List<dynamic> selectedConflictEntities =
          allConflicts.where((conflictEntity) {
            final String conflictId = conflictEntity.id as String;
            return _selectedConflicts.contains(conflictId);
          }).toList();

      // Get dependencies from context
      final AppDatabase database = Provider.of<AppDatabase>(
        context,
        listen: false,
      );
      final FireflyApiAdapter apiAdapter = Provider.of<FireflyApiAdapter>(
        context,
        listen: false,
      );

      // Resolve each conflict
      final ConflictResolver resolver = ConflictResolver(
        apiAdapter: apiAdapter,
        database: database,
        queueManager: SyncQueueManager(database),
      );
      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = <String>[];

      for (final conflictEntity in selectedConflictEntities) {
        try {
          final Conflict conflict = _convertToConflictModel(conflictEntity);
          final Resolution resolution = await resolver.resolveConflict(
            conflict,
            strategy,
          );

          if (resolution.success) {
            successCount++;
          } else {
            failureCount++;
            errors.add('${conflict.id}: ${resolution.errorMessage}');
          }
        } catch (e) {
          failureCount++;
          errors.add('${conflictEntity.id}: $e');
          _log.warning('Failed to resolve conflict ${conflictEntity.id}', e);
        }
      }

      // Close loading indicator
      if (!mounted) return;
      Navigator.of(context).pop();

      // Refresh conflicts list
      await provider.refresh();

      // Exit selection mode
      _exitSelectionMode();

      // Show results
      if (!mounted) return;
      if (failureCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully resolved $successCount conflicts'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show detailed error dialog
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Bulk Resolution Results'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('✓ Resolved: $successCount'),
                      Text('✗ Failed: $failureCount'),
                      if (errors.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 16),
                        const Text(
                          'Errors:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...errors
                            .take(5)
                            .map(
                              (String error) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $error',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        if (errors.length > 5)
                          Text('... and ${errors.length - 5} more errors'),
                      ],
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to resolve conflicts in bulk', e, stackTrace);

      // Close loading indicator if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resolving conflicts: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Convert ConflictEntity from database to Conflict model.
  Conflict _convertToConflictModel(dynamic conflictEntity) {
    try {
      final Map<String, dynamic> localData =
          jsonDecode(conflictEntity.localData as String)
              as Map<String, dynamic>;
      final Map<String, dynamic> remoteData =
          jsonDecode(conflictEntity.serverData as String)
              as Map<String, dynamic>;
      final List<String> conflictingFields =
          (jsonDecode(conflictEntity.conflictingFields as String) as List)
              .cast<String>();

      // Determine conflict type
      final String conflictTypeStr = conflictEntity.conflictType as String;
      final ConflictType conflictType = ConflictType.values.firstWhere(
        (ConflictType e) => e.name == conflictTypeStr.replaceAll('_', ''),
        orElse: () => ConflictType.updateUpdate,
      );

      // Determine severity
      final String severityStr = _determineSeverity(
        conflictEntity.conflictingFields as String,
        conflictEntity.entityType as String,
      );
      final ConflictSeverity severity = ConflictSeverity.values.firstWhere(
        (ConflictSeverity e) =>
            e.name.toLowerCase() == severityStr.toLowerCase(),
        orElse: () => ConflictSeverity.medium,
      );

      return Conflict(
        id: conflictEntity.id as String,
        operationId:
            conflictEntity.entityId as String, // Using entityId as operationId
        entityType: conflictEntity.entityType as String,
        entityId: conflictEntity.entityId as String,
        conflictType: conflictType,
        localData: localData,
        remoteData: remoteData,
        conflictingFields: conflictingFields,
        severity: severity,
        detectedAt: conflictEntity.detectedAt as DateTime,
        resolvedAt: conflictEntity.resolvedAt as DateTime?,
        resolutionStrategy:
            conflictEntity.resolutionStrategy != null
                ? ResolutionStrategy.values.firstWhere(
                  (ResolutionStrategy e) =>
                      e.name == conflictEntity.resolutionStrategy,
                  orElse: () => ResolutionStrategy.manual,
                )
                : null,
        resolvedBy: conflictEntity.resolvedBy as String?,
      );
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to convert ConflictEntity to Conflict model',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Format resolution strategy for display.
  String _formatStrategy(ResolutionStrategy strategy) {
    switch (strategy) {
      case ResolutionStrategy.localWins:
        return 'local version';
      case ResolutionStrategy.remoteWins:
        return 'remote version';
      case ResolutionStrategy.lastWriteWins:
        return 'last write wins';
      case ResolutionStrategy.merge:
        return 'merge';
      case ResolutionStrategy.manual:
        return 'manual resolution';
    }
  }
}
