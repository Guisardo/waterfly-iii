import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';

/// Dialog for manually editing conflict resolution.
///
/// Features:
/// - Pre-fill form with merged data
/// - Allow user to edit any field
/// - Validate input in real-time
/// - Show which fields were changed
/// - Save and Cancel buttons
/// - Confirm before applying changes
class ConflictManualEditDialog extends StatefulWidget {
  final Conflict conflict;
  final Map<String, dynamic> initialData;

  const ConflictManualEditDialog({
    super.key,
    required this.conflict,
    required this.initialData,
  });

  @override
  State<ConflictManualEditDialog> createState() =>
      _ConflictManualEditDialogState();
}

class _ConflictManualEditDialogState extends State<ConflictManualEditDialog> {
  static final Logger _logger = Logger('ConflictManualEditDialog');

  ConflictResolver? _resolver;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolver == null) {
      final AppDatabase database = Provider.of<AppDatabase>(
        context,
        listen: false,
      );
      final FireflyApiAdapter apiAdapter = Provider.of<FireflyApiAdapter>(
        context,
        listen: false,
      );
      _resolver = ConflictResolver(
        apiAdapter: apiAdapter,
        database: database,
        queueManager: SyncQueueManager(database),
      );
    }
  }

  final Map<String, bool> _fieldChanged = <String, bool>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final MapEntry<String, dynamic> entry in widget.initialData.entries) {
      final TextEditingController controller = TextEditingController(
        text: _formatValueForEditing(entry.value),
      );

      controller.addListener(() {
        setState(() {
          _fieldChanged[entry.key] =
              controller.text != _formatValueForEditing(entry.value);
        });
      });

      _controllers[entry.key] = controller;
      _fieldChanged[entry.key] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: <Widget>[
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
                children: <Widget>[
                  Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Manual Edit',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Edit fields to resolve conflict',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
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
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    if (_getChangedFieldsCount() > 0)
                      Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_getChangedFieldsCount()} field${_getChangedFieldsCount() == 1 ? '' : 's'} modified',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ..._buildFieldEditors(),
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
                children: <Widget>[
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child:
                        _isSaving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldEditors() {
    final List<String> fields = widget.initialData.keys.toList()..sort();

    return fields.map((String field) {
      final bool isConflicting = widget.conflict.conflictingFields.contains(
        field,
      );
      final bool isChanged = _fieldChanged[field] ?? false;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (isConflicting)
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                if (isConflicting) const SizedBox(width: 4),
                Text(
                  field,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        isConflicting
                            ? Theme.of(context).colorScheme.error
                            : null,
                  ),
                ),
                if (isChanged) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Modified',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controllers[field],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter $field',
                filled: isConflicting,
                fillColor:
                    isConflicting
                        ? Theme.of(
                          context,
                        ).colorScheme.errorContainer.withValues(alpha: 0.1)
                        : null,
              ),
              validator: (String? value) => _validateField(field, value),
              maxLines: _isMultilineField(field) ? 3 : 1,
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatValueForEditing(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) {
      return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  bool _isMultilineField(String field) {
    return field.toLowerCase().contains('description') ||
        field.toLowerCase().contains('notes') ||
        field.toLowerCase().contains('comment');
  }

  String? _validateField(String field, String? value) {
    if (value == null || value.isEmpty) {
      // Check if field is required
      if (_isRequiredField(field)) {
        return 'This field is required';
      }
      return null;
    }

    // Type-specific validation
    if (field.toLowerCase().contains('amount') ||
        field.toLowerCase().contains('price')) {
      final num? number = num.tryParse(value);
      if (number == null) {
        return 'Must be a valid number';
      }
    }

    if (field.toLowerCase().contains('email')) {
      if (!value.contains('@')) {
        return 'Must be a valid email';
      }
    }

    return null;
  }

  bool _isRequiredField(String field) {
    const List<String> requiredFields = <String>[
      'name',
      'title',
      'amount',
      'date',
    ];
    return requiredFields.any(
      (String req) => field.toLowerCase().contains(req),
    );
  }

  int _getChangedFieldsCount() {
    return _fieldChanged.values.where((bool changed) => changed).length;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int changedCount = _getChangedFieldsCount();
    if (changedCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Save Changes?'),
            content: Text(
              'You have modified $changedCount field${changedCount == 1 ? '' : 's'}. '
              'This will resolve the conflict with your custom values.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> customData = <String, dynamic>{};
      for (final MapEntry<String, TextEditingController> entry
          in _controllers.entries) {
        customData[entry.key] = _parseValue(entry.key, entry.value.text);
      }

      _logger.info('Saving manual conflict resolution with custom data');

      await _resolver!.resolveWithCustomData(widget.conflict.id, customData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conflict resolved with custom data')),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to save manual resolution', e, stackTrace);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  dynamic _parseValue(String field, String value) {
    if (value.isEmpty) return null;

    // Try to parse as number
    if (field.toLowerCase().contains('amount') ||
        field.toLowerCase().contains('price')) {
      return num.tryParse(value) ?? value;
    }

    // Try to parse as bool
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Try to parse as date
    if (field.toLowerCase().contains('date')) {
      final DateTime? date = DateTime.tryParse(value);
      if (date != null) return date;
    }

    return value;
  }
}
