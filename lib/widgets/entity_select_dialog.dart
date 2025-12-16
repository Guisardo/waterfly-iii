import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/widgets/autocompletetext.dart';

/// A generic option type for autocomplete selection.
///
/// This provides a common interface for entities that can be selected
/// in the [EntitySelectDialog], such as bills and piggy banks.
class AutocompleteOption {
  /// Creates an autocomplete option with the given id and name.
  const AutocompleteOption({
    required this.id,
    required this.name,
  });

  /// The unique identifier of the option.
  final String id;

  /// The display name of the option.
  final String name;
}

/// Configuration for the entity selection dialog.
///
/// This class encapsulates all the customization options for the
/// [EntitySelectDialog], allowing it to be used for different entity types
/// like bills and piggy banks.
class EntitySelectConfig<T> {
  /// Creates entity select configuration.
  ///
  /// All parameters are required to properly configure the dialog:
  /// - [icon]: The icon shown in the dialog header
  /// - [title]: The dialog title text
  /// - [labelText]: The label for the autocomplete text field
  /// - [clearButtonText]: Text for the "no selection" button
  /// - [emptyResultFactory]: Factory function to create an empty/null result
  /// - [resultFactory]: Factory function to create a result from selection
  /// - [optionsBuilder]: Async function to fetch autocomplete options
  /// - [initialValue]: Optional initial selected value
  /// - [initialDisplayText]: Optional initial text to display
  const EntitySelectConfig({
    required this.icon,
    required this.title,
    required this.labelText,
    required this.clearButtonText,
    required this.emptyResultFactory,
    required this.resultFactory,
    required this.optionsBuilder,
    this.initialValue,
    this.initialDisplayText,
  });

  /// The icon to display in the dialog header.
  final IconData icon;

  /// The title of the dialog.
  final String title;

  /// The label text for the autocomplete input field.
  final String labelText;

  /// The text for the button that clears the selection.
  final String clearButtonText;

  /// Factory function that creates an empty/null result when user clears selection.
  final T Function() emptyResultFactory;

  /// Factory function that creates a result from an [AutocompleteOption].
  final T Function(AutocompleteOption option) resultFactory;

  /// Async function that fetches autocomplete options based on the query text.
  final Future<Iterable<AutocompleteOption>> Function(String query)
      optionsBuilder;

  /// The initial selected value, if any.
  final T? initialValue;

  /// The initial text to display in the autocomplete field.
  final String? initialDisplayText;
}

/// A versatile dialog for selecting entities with autocomplete support.
///
/// This widget provides a reusable dialog pattern for selecting entities
/// like bills, piggy banks, categories, etc. It features:
/// - Autocomplete text input with search
/// - Clear selection button
/// - Save/cancel actions
/// - Generic typing for result
///
/// Usage:
/// ```dart
/// final result = await showDialog<BillRead>(
///   context: context,
///   builder: (context) => EntitySelectDialog<BillRead>(
///     config: EntitySelectConfig(
///       icon: Icons.calendar_today,
///       title: 'Select Bill',
///       labelText: 'Bill Name',
///       clearButtonText: 'No Bill',
///       emptyResultFactory: () => emptyBill,
///       resultFactory: (option) => BillRead(...),
///       optionsBuilder: (query) => fetchBills(query),
///       initialValue: currentBill,
///       initialDisplayText: currentBill?.attributes.name,
///     ),
///   ),
/// );
/// ```
class EntitySelectDialog<T> extends StatefulWidget {
  /// Creates an entity selection dialog with the given configuration.
  const EntitySelectDialog({
    super.key,
    required this.config,
  });

  /// The configuration for this dialog.
  final EntitySelectConfig<T> config;

  @override
  State<EntitySelectDialog<T>> createState() => _EntitySelectDialogState<T>();
}

class _EntitySelectDialogState<T> extends State<EntitySelectDialog<T>> {
  final Logger _log = Logger('EntitySelectDialog');
  
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  T? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.config.initialValue;
    _textController = TextEditingController(
      text: widget.config.initialDisplayText ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(widget.config.icon),
      title: Text(widget.config.title),
      clipBehavior: Clip.hardEdge,
      scrollable: false,
      actions: <Widget>[
        TextButton(
          child: Text(widget.config.clearButtonText),
          onPressed: () {
            Navigator.of(context).pop(widget.config.emptyResultFactory());
          },
        ),
        FilledButton(
          child: Text(MaterialLocalizations.of(context).saveButtonLabel),
          onPressed: () {
            Navigator.of(context).pop(_selectedValue);
          },
        ),
      ],
      content: SizedBox(
        width: 500,
        child: AutoCompleteText<AutocompleteOption>(
          labelText: widget.config.labelText,
          textController: _textController,
          focusNode: _focusNode,
          errorIconOnly: true,
          displayStringForOption: (AutocompleteOption option) => option.name,
          onSelected: (AutocompleteOption option) {
            _log.finer(() => 'Selected option: ${option.id} (${option.name})');
            setState(() {
              _selectedValue = widget.config.resultFactory(option);
            });
          },
          optionsBuilder: (TextEditingValue textEditingValue) async {
            try {
              return await widget.config.optionsBuilder(textEditingValue.text);
            } catch (e, stackTrace) {
              _log.severe(
                'Error while fetching autocomplete options',
                e,
                stackTrace,
              );
              return const Iterable<AutocompleteOption>.empty();
            }
          },
        ),
      ),
    );
  }
}

