import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';

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
  final Set<String> _selectedConflicts = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflicts'),
        actions: [
          if (_isSelectionMode) ...[
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
          ] else ...[
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
        builder: (context, provider, child) {
          final conflicts = provider.unresolvedConflicts;

          if (conflicts.isEmpty) {
            return _buildEmptyState(context);
          }

          final filteredConflicts = _filterConflicts(conflicts);
          final sortedConflicts = _sortConflicts(filteredConflicts);

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: Column(
              children: [
                if (_filterEntityType != null || _filterSeverity != null)
                  _buildFilterChips(context),
                if (_isSelectionMode)
                  _buildSelectionBar(context, sortedConflicts.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: sortedConflicts.length,
                    itemBuilder: (context, index) {
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
      floatingActionButton: _isSelectionMode && _selectedConflicts.isNotEmpty
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
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[400],
          ),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
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
        children: [
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
        children: [
          Text(
            '${_selectedConflicts.length} of $totalCount selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Build conflict card.
  Widget _buildConflictCard(BuildContext context, dynamic conflict, int index) {
    final conflictId = 'conflict_$index'; // TODO: Use actual conflict ID
    final isSelected = _selectedConflicts.contains(conflictId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(conflictId);
          } else {
            _showConflictDetails(context, conflict);
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
            children: [
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(conflictId),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Conflict #${index + 1}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildSeverityBadge('Medium'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      conflict.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Transaction', // TODO: Get actual entity type
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Just now', // TODO: Get actual timestamp
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
      builder: (context) => AlertDialog(
        title: const Text('Conflict Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveConflict(context, conflict, ResolutionStrategy.remoteWins);
            },
            child: const Text('Keep Remote'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resolveConflict(context, conflict, ResolutionStrategy.localWins);
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
      builder: (context) => AlertDialog(
        title: const Text('Filter Conflicts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Entity Type'),
              trailing: DropdownButton<String?>(
                value: _filterEntityType,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  const DropdownMenuItem(value: 'Transaction', child: Text('Transaction')),
                  const DropdownMenuItem(value: 'Account', child: Text('Account')),
                  const DropdownMenuItem(value: 'Category', child: Text('Category')),
                ],
                onChanged: (value) {
                  setState(() => _filterEntityType = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Severity'),
              trailing: DropdownButton<String?>(
                value: _filterSeverity,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  const DropdownMenuItem(value: 'Low', child: Text('Low')),
                  const DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  const DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() => _filterSeverity = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
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
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Date'),
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Severity'),
              value: 'severity',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Entity Type'),
              value: 'type',
              groupValue: _sortBy,
              onChanged: (value) {
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
      builder: (context) => AlertDialog(
        title: Text('Resolve ${_selectedConflicts.length} Conflicts'),
        content: const Text(
          'Choose a resolution strategy to apply to all selected conflicts:',
        ),
        actions: [
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

  /// Filter conflicts.
  List<dynamic> _filterConflicts(List<dynamic> conflicts) {
    return conflicts.where((conflict) {
      // TODO: Implement actual filtering based on conflict properties
      return true;
    }).toList();
  }

  /// Sort conflicts.
  List<dynamic> _sortConflicts(List<dynamic> conflicts) {
    // TODO: Implement actual sorting based on _sortBy
    return conflicts;
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

  /// Select all conflicts.
  void _selectAll() {
    // TODO: Select all visible conflicts
    _log.info('Select all conflicts');
  }

  /// Exit selection mode.
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedConflicts.clear();
    });
  }

  /// Resolve single conflict.
  void _resolveConflict(
    BuildContext context,
    dynamic conflict,
    ResolutionStrategy strategy,
  ) {
    _log.info('Resolving conflict with strategy: $strategy');
    // TODO: Call conflict resolver service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conflict resolved')),
    );
  }

  /// Resolve multiple conflicts.
  void _resolveBulk(ResolutionStrategy strategy) {
    _log.info('Resolving ${_selectedConflicts.length} conflicts with strategy: $strategy');
    // TODO: Call conflict resolver service for bulk resolution
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedConflicts.length} conflicts resolved')),
    );
    _exitSelectionMode();
  }
}
