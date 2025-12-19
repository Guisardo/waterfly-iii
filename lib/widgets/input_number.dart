import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/services/math_expression_evaluator.dart';

class NumberInput extends StatelessWidget {
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

  static final Logger _log = Logger('NumberInput');

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: value,
      onChanged: _handleOnChanged,
      readOnly: disabled,
      enabled: !disabled,
      keyboardType: TextInputType.numberWithOptions(decimal: (decimals > 0)),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(_getRegexString())),
        TextInputFormatter.withFunction(
          (TextEditingValue oldValue, TextEditingValue newValue) =>
              newValue.copyWith(text: newValue.text.replaceAll(',', '.')),
        ),
      ],
      decoration: InputDecoration(
        label: (label != null) ? Text(label!) : null,
        hintText: hintText,
        errorText: error,
        icon: icon,
        border: const OutlineInputBorder(),
        prefixText: prefixText,
        filled: disabled,
      ),
      style:
          disabled
              ? style?.copyWith(color: Theme.of(context).disabledColor)
              : style,
    );
  }

  /// Handles the onChanged callback with expression evaluation support.
  ///
  /// First attempts to evaluate the input as a math expression.
  /// If evaluation succeeds, passes the result to the original callback.
  /// If evaluation fails, falls back to direct parsing for backward compatibility.
  void _handleOnChanged(String input) {
    if (onChanged == null) {
      return;
    }

    _log.fine(() => 'Input changed: "$input"');

    // Try to evaluate as expression first
    final double? evaluatedResult = _evaluateExpression(input);

    if (evaluatedResult != null) {
      // Expression evaluation succeeded - pass the result
      _log.fine(() => 'Expression evaluated to: $evaluatedResult');
      final String resultString = _formatResult(evaluatedResult);
      onChanged!(resultString);
    } else {
      // Expression evaluation failed - fall back to direct parsing
      // This maintains backward compatibility with numeric-only input
      _log.fine('Expression evaluation failed, using direct parsing');
      onChanged!(input);
    }
  }

  /// Evaluates a string input as a math expression.
  ///
  /// Returns the evaluated result if the input is a valid expression,
  /// or null if it's not an expression or evaluation fails.
  double? _evaluateExpression(String input) {
    if (input.isEmpty || input.trim().isEmpty) {
      return null;
    }

    // Check if input contains any operators
    final bool hasOperator =
        input.contains('+') ||
        input.contains('-') ||
        input.contains('*') ||
        input.contains('/');

    // If no operators, it's not an expression - return null to use direct parsing
    if (!hasOperator) {
      return null;
    }

    // Attempt to evaluate as expression
    return MathExpressionEvaluator.evaluate(input);
  }

  /// Formats the evaluation result according to the decimals setting.
  ///
  /// Ensures the result respects the decimal places configuration.
  String _formatResult(double result) {
    // Format with appropriate decimal places
    if (decimals > 0) {
      return result.toStringAsFixed(decimals);
    } else {
      return result.toStringAsFixed(0);
    }
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
    if (decimals > 0) {
      // With decimals: allow numbers with decimal points and operators
      return r'[0-9+\-*/.,]';
    } else {
      // Without decimals: allow numbers and operators (no decimal point)
      return r'[0-9+\-*/]';
    }
  }
}
