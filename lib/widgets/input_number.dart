import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/services/math_expression_evaluator.dart';

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

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  late FocusNode _focusNode;
  late TextEditingController _internalController;
  bool _hasInternalController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    // Use provided controller or create internal one
    if (widget.controller != null) {
      _internalController = widget.controller!;
      // Initialize with value if provided and controller is empty
      if (widget.value != null &&
          widget.value!.isNotEmpty &&
          _internalController.text.isEmpty) {
        _internalController.text = widget.value!;
      }
    } else {
      _internalController = TextEditingController(text: widget.value ?? '');
      _hasInternalController = true;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (_hasInternalController) {
      _internalController.dispose();
    }
    super.dispose();
  }

  /// Handles focus changes - evaluates expression when field loses focus
  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _evaluateCurrentExpression();
    }
  }

  /// Evaluates the current expression in the field
  void _evaluateCurrentExpression() {
    final String input = _internalController.text;
    if (input.isEmpty) {
      return;
    }

    // Check if input contains any operators
    final bool hasOperator =
        input.contains('+') ||
        input.contains('-') ||
        input.contains('*') ||
        input.contains('/');

    if (!hasOperator) {
      return;
    }

    // Attempt to evaluate
    final double? result = MathExpressionEvaluator.evaluate(input);
    if (result != null) {
      final String resultString = _formatResult(result);
      _internalController.value = TextEditingValue(
        text: resultString,
        selection: TextSelection.collapsed(offset: resultString.length),
      );
      widget.onChanged?.call(resultString);
    }
  }

  /// Formats the evaluation result according to the decimals setting.
  String _formatResult(double result) {
    if (widget.decimals > 0) {
      return result.toStringAsFixed(widget.decimals);
    } else {
      return result.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _internalController,
      focusNode: _focusNode,
      onChanged: _handleOnChanged,
      onFieldSubmitted: (_) => _evaluateCurrentExpression(),
      onEditingComplete: _evaluateCurrentExpression,
      readOnly: widget.disabled,
      enabled: !widget.disabled,
      keyboardType: TextInputType.numberWithOptions(
        decimal: (widget.decimals > 0),
      ),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(_getRegexString())),
        TextInputFormatter.withFunction(
          (TextEditingValue oldValue, TextEditingValue newValue) =>
              newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
        ),
        _ExpressionEvaluatorFormatter(
          decimals: widget.decimals,
          onEvaluated: (String result) {
            widget.onChanged?.call(result);
          },
        ),
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
      style:
          widget.disabled
              ? widget.style?.copyWith(color: Theme.of(context).disabledColor)
              : widget.style,
    );
  }

  /// Handles the onChanged callback.
  ///
  /// Expression evaluation is handled by the TextInputFormatter,
  /// which replaces expression text with evaluated results.
  /// This method simply passes through the input (which may be an evaluated result).
  void _handleOnChanged(String input) {
    widget.onChanged?.call(input);
  }

  /// Returns the regex pattern for input validation.
  ///
  /// Allows:
  /// - Digits (0-9)
  /// - Decimal separators (.,)
  /// - Math operators (+, -, *, /)
  ///
  /// Note: The regex is permissive to allow expression input,
  /// but the expression evaluator will validate the final expression.
  String _getRegexString() {
    // Allow digits, decimal separators, and math operators
    // Escape special regex characters: - (needs to be at start/end or escaped), * (needs escaping)
    // Note: No ^ and $ anchors to allow partial input during typing
    if (widget.decimals > 0) {
      // With decimals: allow numbers with decimal points and operators
      return r'[0-9+\-*/.,]';
    } else {
      // Without decimals: allow numbers and operators (no decimal point)
      return r'[0-9+\-*/]';
    }
  }
}

/// TextInputFormatter that evaluates math expressions in real-time.
///
/// Evaluates expressions when:
/// - A second operator is pressed (chaining calculations: "10+5*" -> "15*")
/// - Expression ends with a number (complete expression)
class _ExpressionEvaluatorFormatter extends TextInputFormatter {
  _ExpressionEvaluatorFormatter({
    required this.decimals,
    required this.onEvaluated,
  });

  final int decimals;
  final void Function(String result) onEvaluated;

  static final Logger _log = Logger('ExpressionEvaluatorFormatter');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String input = newValue.text;
    final String oldInput = oldValue.text;

    // If empty, return as-is
    if (input.isEmpty) {
      return newValue;
    }

    // Check if input contains any operators
    final bool hasOperator =
        input.contains('+') ||
        input.contains('-') ||
        input.contains('*') ||
        input.contains('/');

    // If no operators, it's not an expression - return as-is
    if (!hasOperator) {
      return newValue;
    }

    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return newValue;
    }

    final String lastChar = trimmed[trimmed.length - 1];
    final bool lastCharIsOperator = RegExp(r'[+\-*/]').hasMatch(lastChar);

    // Detect if a second operator was just pressed (chaining calculation)
    // Check if the last character is an operator and the input length increased
    final bool operatorJustPressed =
        lastCharIsOperator &&
        input.length > oldInput.length &&
        oldInput.isNotEmpty;

    if (operatorJustPressed) {
      // User pressed a second operator - evaluate the previous expression
      // Extract the expression before the new operator
      final String expressionBeforeOperator =
          trimmed.substring(0, trimmed.length - 1).trim();

      if (expressionBeforeOperator.isNotEmpty) {
        final double? evaluatedResult = MathExpressionEvaluator.evaluate(
          expressionBeforeOperator,
        );

        if (evaluatedResult != null) {
          // Expression evaluation succeeded - replace with result + new operator
          _log.fine(
            () =>
                'Chained expression "$expressionBeforeOperator" evaluated to $evaluatedResult',
          );

          final String resultString = _formatResult(evaluatedResult);
          final String newText = '$resultString$lastChar';

          // Notify parent component of the evaluated result (without the operator)
          onEvaluated(resultString);

          // Return result + new operator so user can continue calculation
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    }

    // Don't evaluate automatically - only evaluate on:
    // 1. Second operator press (handled above)
    // 2. Enter key (handled by onFieldSubmitted/onEditingComplete)
    // 3. Focus loss (handled by focus listener)
    // This allows users to type full numbers after operators
    return newValue;
  }

  /// Formats the evaluation result according to the decimals setting.
  String _formatResult(double result) {
    if (decimals > 0) {
      return result.toStringAsFixed(decimals);
    } else {
      return result.toStringAsFixed(0);
    }
  }
}
