import 'package:expressions/expressions.dart';
import 'package:logging/logging.dart';

/// Math Expression Evaluator Service
///
/// Thin wrapper around the [expressions] package providing arithmetic
/// evaluation with operator precedence (+, -, *, /), decimal support,
/// and partial expression evaluation for chained calculations.
///
/// Example:
/// ```dart
/// final evaluator = MathExpressionEvaluator();
/// final result = evaluator.evaluate('10+5*2'); // Returns 20.0
/// final partial = evaluator.evaluatePartial('10+5*'); // Returns 15.0
/// ```
class MathExpressionEvaluator {
  MathExpressionEvaluator() : _log = Logger('MathExpressionEvaluator');

  final Logger _log;
  static const ExpressionEvaluator _evaluator = ExpressionEvaluator();

  /// Normalizes an expression by removing whitespace and replacing commas
  /// with dots for decimal separator compatibility.
  String _normalize(String expression) {
    return expression.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
  }

  /// Evaluates a complete mathematical expression.
  ///
  /// Supports operators: +, -, *, /
  /// Handles operator precedence correctly via the [expressions] package.
  ///
  /// Parameters:
  /// - [expression]: The mathematical expression to evaluate
  ///
  /// Returns:
  /// - [double?] The evaluation result, or null if the expression is invalid,
  ///   produces Infinity (division by zero), or produces NaN (0/0)
  double? evaluate(String expression) {
    if (expression.isEmpty) {
      _log.fine('Empty expression provided');
      return null;
    }

    final String normalized = _normalize(expression);
    _log.fine(() => 'Evaluating expression: $normalized');

    final Expression? parsed = Expression.tryParse(normalized);
    if (parsed == null) {
      _log.warning('Failed to parse expression: $normalized');
      return null;
    }

    try {
      final dynamic result = _evaluator.eval(parsed, <String, dynamic>{});
      if (result is! num) {
        _log.warning('Non-numeric result for expression: $normalized');
        return null;
      }
      final double value = result.toDouble();
      if (value.isNaN || value.isInfinite) {
        _log.warning('NaN or Infinite result for expression: $normalized');
        return null;
      }
      _log.fine(() => 'Evaluation result: $value');
      return value;
    } catch (e, stackTrace) {
      _log.severe('Error evaluating expression: $expression', e, stackTrace);
      return null;
    }
  }

  /// Evaluates a partial expression up to the last operator.
  ///
  /// Used for chained calculations when a second operator is pressed.
  /// For example, "10+5*" would evaluate to 15.0 (evaluates "10+5").
  ///
  /// Parameters:
  /// - [expression]: The partial expression ending with an operator
  ///
  /// Returns:
  /// - [double?] The evaluation result, or null if the expression is invalid
  double? evaluatePartial(String expression) {
    if (expression.isEmpty) {
      _log.fine('Empty partial expression provided');
      return null;
    }

    _log.fine(() => 'Evaluating partial expression: $expression');

    final String normalized = _normalize(expression);
    final String withoutTrailing = normalized.replaceAll(
      RegExp(r'[+\-*/]$'),
      '',
    );

    if (withoutTrailing.isEmpty) {
      _log.fine('Expression contains only operator');
      return null;
    }

    return evaluate(withoutTrailing);
  }

  /// Returns true only if [expression] evaluates to a finite, non-NaN number.
  ///
  /// This correctly rejects division by zero (returns Infinity) and 0/0
  /// (returns NaN) in addition to malformed expressions.
  bool isValidExpression(String expression) {
    return evaluate(expression) != null;
  }
}
