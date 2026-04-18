import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/utils/math_expression_evaluator.dart';
import 'package:waterflyiii/widgets/number_keyboard.dart';

/// A numeric text input field with an optional custom math keyboard.
///
/// When [showMathKeyboard] is true (default), tapping the field suppresses
/// the system keyboard and shows [NumberKeyboard] instead, which exposes
/// arithmetic operators (+, −, ×, ÷, %) alongside the digits. The expression
/// is evaluated with [MathExpressionEvaluator] on = press or focus loss.
///
/// When [showMathKeyboard] is false the widget behaves like a plain numeric
/// [TextFormField] (system keyboard, no expression evaluation).
class NumberInput extends StatefulWidget {
  const NumberInput({
    super.key,
    this.label,
    this.controller,
    this.value,
    this.onChanged,
    this.error,
    this.icon,
    this.hintText,
    this.prefixText,
    this.decimals = 0,
    this.disabled = false,
    this.style,
    this.focusNode,
    this.showMathKeyboard = true,
  });

  final TextEditingController? controller;
  final String? value;
  final String? label;
  final Function? onChanged;
  final String? error;
  final Widget? icon;
  final String? hintText;
  final String? prefixText;
  final int decimals;
  final bool disabled;
  final TextStyle? style;

  /// External [FocusNode] to attach to the underlying [TextFormField].
  /// If null, an internal node is created automatically.
  final FocusNode? focusNode;

  /// Whether to show the custom [NumberKeyboard] overlay instead of the
  /// system keyboard. Defaults to true.
  final bool showMathKeyboard;

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  final Logger _log = Logger('NumberInput');
  final MathExpressionEvaluator _evaluator = MathExpressionEvaluator();

  late final FocusNode _focusNode;
  bool _ownsNode = false;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _hideKeyboard();
    if (_ownsNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Focus handling
  // ---------------------------------------------------------------------------

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.showMathKeyboard && !widget.disabled) {
        _showKeyboard();
      }
    } else {
      _hideKeyboard();
      _evaluateOnBlur();
    }
  }

  void _showKeyboard() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (BuildContext ctx) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: NumberKeyboard(
          hasDecimal: widget.decimals > 0,
          onKey: _insertKey,
          onBackspace: _handleBackspace,
          onClear: _handleClear,
          onEquals: _handleEquals,
          onPercent: _handlePercent,
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideKeyboard() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ---------------------------------------------------------------------------
  // Keyboard key handlers
  // ---------------------------------------------------------------------------

  void _insertKey(String key) {
    final TextEditingController? ctrl = widget.controller;
    if (ctrl == null) {
      return;
    }

    final TextSelection selection = ctrl.selection;
    final String text = ctrl.text;

    final int start = selection.start < 0 ? text.length : selection.start;
    final int end = selection.end < 0 ? text.length : selection.end;

    final String newText = text.substring(0, start) + key + text.substring(end);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + key.length),
    );
    widget.onChanged?.call(ctrl.text);
    _log.fine(() => 'Inserted "$key" → "${ctrl.text}"');
  }

  void _handleBackspace() {
    final TextEditingController? ctrl = widget.controller;
    if (ctrl == null) {
      return;
    }

    final TextSelection selection = ctrl.selection;
    final String text = ctrl.text;

    if (selection.start != selection.end) {
      // Delete selected range
      final String newText =
          text.substring(0, selection.start) + text.substring(selection.end);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      final int offset = selection.start < 0 ? text.length : selection.start;
      if (offset <= 0) {
        return;
      }
      final String newText =
          text.substring(0, offset - 1) + text.substring(offset);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: offset - 1),
      );
    }
    widget.onChanged?.call(ctrl.text);
  }

  void _handleClear() {
    final TextEditingController? ctrl = widget.controller;
    if (ctrl == null) {
      return;
    }
    ctrl.clear();
    widget.onChanged?.call('');
    _log.fine(() => 'Cleared input');
  }

  void _handlePercent() {
    final TextEditingController? ctrl = widget.controller;
    if (ctrl == null) {
      return;
    }
    if (ctrl.text.isEmpty) {
      return;
    }
    final double? value = _evaluator.evaluate(ctrl.text);
    if (value == null) {
      return;
    }
    final double percentValue = value / 100.0;
    final String formatted = _formatResult(percentValue);
    ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    widget.onChanged?.call(formatted);
    _log.fine(() => 'Percent: ${ctrl.text} → $formatted');
  }

  void _handleEquals() {
    _evaluateExpression(isFullEvaluation: true);
    _focusNode.unfocus();
  }

  // ---------------------------------------------------------------------------
  // Expression evaluation
  // ---------------------------------------------------------------------------

  void _evaluateOnBlur() {
    if (widget.showMathKeyboard) {
      _evaluateExpression(isFullEvaluation: true);
    }
  }

  void _evaluateExpression({required bool isFullEvaluation}) {
    final TextEditingController? ctrl = widget.controller;
    if (ctrl == null || ctrl.text.isEmpty) {
      return;
    }

    _log.fine(() => 'Evaluating "${ctrl.text}" (full: $isFullEvaluation)');

    double? result;
    if (isFullEvaluation) {
      result = _evaluator.evaluate(ctrl.text);
    } else {
      result = _evaluator.evaluatePartial(ctrl.text);
    }

    if (result == null) {
      return;
    }

    final String formatted = _formatResult(result);
    ctrl.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    widget.onChanged?.call(formatted);
    _log.fine(() => 'Evaluated "${ctrl.text}" → $formatted');
  }

  String _formatResult(double result) {
    return result.toStringAsFixed(widget.decimals);
  }

  // ---------------------------------------------------------------------------
  // Input formatter helpers
  // ---------------------------------------------------------------------------

  RegExp _getRegex() => (widget.decimals > 0)
      ? RegExp(r'^[0-9]+[,.]{0,1}[0-9]{0,' + widget.decimals.toString() + r'}$')
      : RegExp(r'^[0-9]+$');

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      initialValue: widget.value,
      onChanged: widget.onChanged as void Function(String)?,
      readOnly: widget.disabled,
      enabled: !widget.disabled,
      // Suppress system keyboard when custom keyboard is active.
      keyboardType: (widget.showMathKeyboard && !widget.disabled)
          ? TextInputType.none
          : TextInputType.numberWithOptions(decimal: (widget.decimals > 0)),
      inputFormatters: <TextInputFormatter>[
        TextInputFormatter.withFunction(
          (TextEditingValue oldValue, TextEditingValue newValue) =>
              newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
        ),
        TextInputFormatter.withFunction((
          TextEditingValue oldValue,
          TextEditingValue newValue,
        ) {
          if (newValue.composing != TextRange.empty) {
            return newValue;
          }

          // Check for operators in newValue (excluding leading minus for negative numbers)
          final String textWithoutLeadingMinus = newValue.text.startsWith('-')
              ? newValue.text.substring(1)
              : newValue.text;
          final int opCount = RegExp(
            r'[+\-*/]',
          ).allMatches(textWithoutLeadingMinus).length;

          // No operators → normal number validation
          if (opCount == 0) {
            if (newValue.text.isNotEmpty &&
                !_getRegex().hasMatch(newValue.text)) {
              return oldValue;
            }
            return newValue;
          }

          // Allow multiple operators — expression will be evaluated on blur
          final List<String> numbers = newValue.text.split(RegExp(r'[+\-*/]'));
          for (int i = 0; i < numbers.length; i++) {
            if (numbers[i].isNotEmpty &&
                !RegExp(r'^[0-9]+[,.]?[0-9]*$').hasMatch(numbers[i])) {
              return oldValue;
            }
          }

          return newValue;
        }),
      ],
      decoration: InputDecoration(
        label: (widget.label != null) ? Text(widget.label!) : null,
        hintText: widget.hintText,
        errorText: widget.error,
        icon: widget.icon,
        border: const OutlineInputBorder(),
        prefixText: widget.prefixText,
        filled: widget.disabled,
      ),
      style: widget.disabled
          ? widget.style?.copyWith(color: Theme.of(context).disabledColor)
          : widget.style,
    );
  }
}
