import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/conflict.dart';
import '../database/conflicts_table.dart';
import '../services/sync/conflict_resolver.dart';
import 'conflict_resolution_dialog.dart';

/// Screen displaying all unresolved conflicts.
///
/// Features:
/// - Display all unresolved conflicts
/// - Group by entity type
/// - Color-coded severity
/// - Search and filter options
/// - Show conflict age
/// - Tappable items to open resolution dialog
/// - "Auto-Resolve All" button
class ConflictListScreen extends StatefulWidget {
  const ConflictListScreen({super.key});

  @override
  State<ConflictListScreen> createState() => _ConflictListScreenState();
}

class _ConflictListScreenState extends State<ConflictListScreen> {
  static final Logger _logger = Logger('ConflictListScreen');

  final ConflictsTable _conflictsTable = ConflictsTable();
  final ConflictResolver _resolver = ConflictResolver();

  String _searchQuery = '';
  String _filterSeverity = 'all';
  String _groupBy = 'entity'; // entity, severity, age

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflicts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterSeverity = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Severities')),
              const PopupMenuItem(value: 'high', child: Text('High')),
              const PopupMenuItem(value: 'medium', child: Text('Medium')),
              const PopupMenuItem(value: 'low', child: Text('Low')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Conflict>>(
        future: _loadConflicts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final conflicts = snapshot.data ?? [];

          if (conflicts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conflicts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All data is in sync',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          final grouped = _groupConflicts(conflicts);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final group = grouped[index];
              return _buildConflictGroup(group);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _autoResolveAll,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Auto-Resolve All'),
      ),
    );
  }

  Widget _buildConflictGroup(Map<String, dynamic> group) {
    final title = group['title'] as String;
    final conflicts = group['conflicts'] as List<Conflict>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$title (${conflicts.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ...conflicts.map((conflict) => _buildConflictTile(conflict)),
        ],
      ),
    );
  }

  Widget _buildConflictTile(Conflict conflict) {
    final severityColor = _getSeverityColor(conflict.severity);
    final age = DateTime.now().difference(conflict.detectedAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: severityColor.withOpacity(0.2),
        child: Icon(
          _getSeverityIcon(conflict.severity),
          color: severityColor,
          size: 20,
        ),
      ),
      title: Text(conflict.entityType),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(conflict.conflictType.toString().split('.').last),
          Text(
            '${conflict.conflictingFields.length} field${conflict.conflictingFields.length == 1 ? '' : 's'} • ${_formatAge(age)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Chip(
        label: Text(conflict.severity.toString().split('.').last),
        backgroundColor: severityColor.withOpacity(0.2),
        labelStyle: TextStyle(color: severityColor, fontSize: 12),
      ),
      onTap: () => _openConflictResolution(conflict),
    );
  }

  Color _getSeverityColor(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.high:
        return Theme.of(context).colorScheme.error;
      case ConflictSeverity.medium:
        return Theme.of(context).colorScheme.tertiary;
      case ConflictSeverity.low:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getSeverityIcon(ConflictSeverity severity) {
    switch (severity) {
      case ConflictSeverity.high:
        return Icons.error;
      case ConflictSeverity.medium:
        return Icons.warning;
      case ConflictSeverity.low:
        return Icons.info;
    }
  }

  String _formatAge(Duration age) {
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  List<Map<String, dynamic>> _groupConflicts(List<Conflict> conflicts) {
    final groups = <String, List<Conflict>>{};

    for (final conflict in conflicts) {
      final key = _groupBy == 'entity'
          ? conflict.entityType
          : _groupBy == 'severity'
              ? conflict.severity.toString().split('.').last
              : 'Recent';

      groups.putIfAbsent(key, () => []).add(conflict);
    }

    return groups.entries
        .map((e) => {'title': e.key, 'conflicts': e.value})
        .toList();
  }

  Future<List<Conflict>> _loadConflicts() async {
    try {
      var conflicts = await _conflictsTable.getUnresolvedConflicts();

      if (_searchQuery.isNotEmpty) {
        conflicts = conflicts
            .where((c) =>
                c.entityType.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }

      if (_filterSeverity != 'all') {
        conflicts = conflicts
            .where((c) =>
                c.severity.toString().split('.').last == _filterSeverity)
            .toList();
      }

      return conflicts;
    } catch (e, stackTrace) {
      _logger.severe('Failed to load conflicts', e, stackTrace);
      rethrow;
    }
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _ConflictSearchDelegate(
        onQueryChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
      ),
    );
  }

  Future<void> _openConflictResolution(Conflict conflict) async {
    final resolved = await showDialog<bool>(
      context: context,
      builder: (context) => ConflictResolutionDialog(conflict: conflict),
    );

    if (resolved == true) {
      setState(() {});
    }
  }

  Future<void> _autoResolveAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Resolve All Conflicts?'),
        content: const Text(
          'This will automatically resolve all low-severity conflicts using '
          'the last-write-wins strategy. Medium and high severity conflicts '
          'will require manual resolution.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Auto-Resolve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _resolver.autoResolveConflicts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-resolved conflicts')),
        );
        setState(() {});
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to auto-resolve conflicts', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to auto-resolve: $e')),
        );
      }
    }
  }
}

class _ConflictSearchDelegate extends SearchDelegate<String> {
  final Function(String) onQueryChanged;

  _ConflictSearchDelegate({required this.onQueryChanged});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onQueryChanged('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onQueryChanged(query);
    close(context, query);
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
