import 'dart:async';
import 'package:async/async.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/utils/autocomplete_recency.dart';
import 'package:waterflyiii/widgets/erroricon.dart';

final Logger log = Logger("Widgets.AutoCompleteText");

class AutoCompleteText<T extends Object> extends StatefulWidget {
  const AutoCompleteText({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.labelText,
    required this.optionsBuilder,
    this.labelIcon,
    this.displayStringForOption = defaultStringForOption,
    this.disabled = false,
    this.onSelected,
    this.onChanged,
    this.style,
    this.errorText,
    this.errorIconOnly = false,
    this.recencyField,
    this.recencyKeyForOption,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final String labelText;
  final FutureOr<Iterable<T>> Function(TextEditingValue) optionsBuilder;
  final IconData? labelIcon;
  final String Function(T) displayStringForOption;
  final bool disabled;
  final void Function(T)? onSelected;
  final void Function(String)? onChanged;
  final TextStyle? style;
  final String? errorText;
  final bool errorIconOnly;

  /// Set only for transaction-editor suggestions.
  final String? recencyField;
  final String Function(T)? recencyKeyForOption;

  static String defaultStringForOption(dynamic option) {
    return option.toString();
  }

  @override
  State<AutoCompleteText<T>> createState() => _AutoCompleteTextState<T>();
}

class _AutoCompleteTextState<T extends Object>
    extends State<AutoCompleteText<T>> {
  Future<AutocompleteRecency>? _recency;
  final Set<CancelableOperation<Iterable<T>>> _pending =
      <CancelableOperation<Iterable<T>>>{};

  Future<Iterable<T>> _lifecycleOptions(TextEditingValue value) {
    final CancelableOperation<Iterable<T>> operation =
        CancelableOperation<Iterable<T>>.fromFuture(
          Future<Iterable<T>>.sync(
            () => widget.recencyField == null
                ? widget.optionsBuilder(value)
                : _recentOptions(value),
          ),
        );
    _pending.add(operation);
    // Cancelled values intentionally never resume RawAutocomplete after disposal.
    return operation.value.whenComplete(() {
      _pending.remove(operation);
    });
  }

  @override
  void dispose() {
    widget.textController.removeListener(_handleTextChanges);
    for (final CancelableOperation<Iterable<T>> operation in _pending) {
      unawaited(operation.cancel());
    }
    _pending.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AutoCompleteText<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_handleTextChanges);
      widget.textController.addListener(_handleTextChanges);
    }
  }

  Future<Iterable<T>> _recentOptions(TextEditingValue value) async {
    final Iterable<T> options = await widget.optionsBuilder(value);
    if (!mounted) {
      return <T>[];
    }
    try {
      final AutocompleteRecency recency = await (_recency ??=
          AutocompleteRecency.load());
      if (!mounted) {
        return <T>[];
      }
      return recency.sorted<T>(
        widget.recencyField!,
        options,
        widget.recencyKeyForOption ?? widget.displayStringForOption,
      );
    } catch (error, stack) {
      log.warning('Could not rank recent suggestions', error, stack);
      return options;
    }
  }

  @override
  void initState() {
    super.initState();

    widget.textController.addListener(_handleTextChanges);
  }

  void _handleTextChanges() {
    setState(() {
      if (widget.textController.text.isEmpty && widget.onChanged != null) {
        widget.onChanged!("");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    log.finest(() => "build(labelText: $widget.labelText)");
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          RawAutocomplete<T>(
            textEditingController: widget.textController,
            focusNode: widget.focusNode,
            onSelected: widget.onSelected,
            displayStringForOption: widget.displayStringForOption,
            optionsBuilder: _lifecycleOptions,
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  void onFieldSubmitted,
                ) => TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onChanged: widget.onChanged,
                  readOnly: widget.disabled,
                  enabled: !widget.disabled,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: widget.labelText,
                    icon: (widget.labelIcon != null)
                        ? Icon(widget.labelIcon)
                        : null,
                    filled: widget.disabled,
                    suffixIcon: widget.errorText != null && widget.errorIconOnly
                        ? const ErrorIcon(true)
                        : textEditingController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() {
                              textEditingController.clear();
                              focusNode.requestFocus();
                            }),
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    errorText: widget.errorText,
                    errorStyle: widget.errorIconOnly
                        ? const TextStyle(fontSize: 0)
                        : null,
                  ),
                  enableSuggestions: true,
                  style: widget.disabled
                      ? widget.style?.copyWith(
                          color: Theme.of(context).disabledColor,
                        )
                      : widget.style,
                  onTapOutside: (_) {
                    final BuildContext? ctx =
                        FocusManager.instance.primaryFocus?.context;
                    if (!focusNode.hasFocus || ctx == null) {
                      return;
                    }
                    Actions.invoke(ctx, const DismissIntent());
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
            optionsViewBuilder:
                (
                  BuildContext context,
                  void Function(T) onOptionSelected,
                  Iterable<T> options,
                ) => Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: widget.labelIcon == null ? 0 : 40,
                    ),
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth:
                              constraints.biggest.width -
                              (widget.labelIcon == null ? 0 : 40),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            final T option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onOptionSelected(option),
                              child: Builder(
                                builder: (BuildContext context) {
                                  final bool highlight =
                                      AutocompleteHighlightedOption.of(
                                        context,
                                      ) ==
                                      index;
                                  if (highlight) {
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) {
                                          Scrollable.ensureVisible(
                                            context,
                                            alignment: 0.5,
                                          );
                                        });
                                  }
                                  return Container(
                                    color: highlight
                                        ? Theme.of(context).focusColor
                                        : null,
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      widget.displayStringForOption(option),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }
}
