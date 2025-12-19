import 'package:logging/logging.dart';

/// Math Expression Evaluator
///
/// Safely evaluates simple arithmetic expressions containing basic operators:
/// - Addition (+)
/// - Subtraction (-)
/// - Multiplication (*)
/// - Division (/)
///
/// Features:
/// - Operator precedence (multiplication/division before addition/subtraction)
/// - Safe evaluation with no code execution
/// - Comprehensive error handling
/// - Division by zero detection
///
/// Example:
/// ```dart
/// final result = MathExpressionEvaluator.evaluate('10+5*2');
/// print(result); // 20.0 (not 30.0 - correct precedence)
/// ```
class MathExpressionEvaluator {
  MathExpressionEvaluator._(); // Private constructor - static only

  static final Logger _log = Logger('MathExpressionEvaluator');

  /// Evaluates a simple arithmetic expression.
  ///
  /// Supports operators: +, -, *, /
  /// Handles operator precedence correctly (PEMDAS-like, but only for basic ops).
  ///
  /// Parameters:
  /// - [expression]: The expression string to evaluate (e.g., "10+5*2")
  ///
  /// Returns:
  /// - `double?`: The evaluated result, or `null` if the expression is invalid
  ///
  /// Examples:
  /// - `evaluate("10+5")` → `15.0`
  /// - `evaluate("20*3")` → `60.0`
  /// - `evaluate("10+5*2")` → `20.0` (correct precedence)
  /// - `evaluate("10/0")` → `null` (division by zero)
  /// - `evaluate("++")` → `null` (invalid expression)
  static double? evaluate(String expression) {
    _log.fine(() => 'Evaluating expression: "$expression"');

    if (expression.isEmpty || expression.trim().isEmpty) {
      _log.fine('Expression is empty');
      return null;
    }

    // Remove whitespace
    final String cleaned = expression.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) {
      _log.fine('Expression is whitespace only');
      return null;
    }

    try {
      // Parse expression into tokens (numbers and operators)
      final List<Token> tokens = _parseTokens(cleaned);
      if (tokens.isEmpty) {
        _log.warning('No valid tokens found in expression: "$expression"');
        return null;
      }

      // Validate token sequence
      if (!_validateTokens(tokens)) {
        _log.warning('Invalid token sequence in expression: "$expression"');
        return null;
      }

      // Evaluate with operator precedence
      final double? result = _evaluateWithPrecedence(tokens);
      if (result == null) {
        _log.warning('Evaluation failed for expression: "$expression"');
        return null;
      }

      _log.fine(() => 'Expression "$expression" evaluated to $result');
      return result;
    } catch (e, stackTrace) {
      _log.severe('Error evaluating expression: "$expression"', e, stackTrace);
      return null;
    }
  }

  /// Parses a string expression into a list of tokens (numbers and operators).
  ///
  /// Handles:
  /// - Decimal numbers (e.g., "10.5", "3.14")
  /// - Negative numbers at start (e.g., "-5")
  /// - Operators: +, -, *, /
  static List<Token> _parseTokens(String expression) {
    final List<Token> tokens = <Token>[];
    final StringBuffer numberBuffer = StringBuffer();

    for (int i = 0; i < expression.length; i++) {
      final String char = expression[i];

      if (_isDigit(char) || char == '.') {
        // Building a number
        numberBuffer.write(char);
      } else if (_isOperator(char)) {
        // Flush number buffer if it has content
        if (numberBuffer.isNotEmpty) {
          final String numberStr = numberBuffer.toString();
          final double? number = double.tryParse(numberStr);
          if (number != null) {
            tokens.add(Token.number(number));
          } else {
            _log.warning('Failed to parse number: "$numberStr"');
            return <Token>[]; // Invalid number
          }
          numberBuffer.clear();
        }

        // Handle negative number at start or after operator
        if (char == '-' && (tokens.isEmpty || tokens.last.isOperator)) {
          // This is a negative sign, not subtraction
          numberBuffer.write(char);
        } else {
          // Add operator token
          tokens.add(Token.operator(char));
        }
      } else {
        // Invalid character
        _log.warning('Invalid character in expression: "$char"');
        return <Token>[];
      }
    }

    // Flush remaining number buffer
    if (numberBuffer.isNotEmpty) {
      final String numberStr = numberBuffer.toString();
      final double? number = double.tryParse(numberStr);
      if (number != null) {
        tokens.add(Token.number(number));
      } else {
        _log.warning('Failed to parse number: "$numberStr"');
        return <Token>[];
      }
    }

    return tokens;
  }

  /// Validates that the token sequence is valid.
  ///
  /// Rules:
  /// - Must start with a number (or negative number)
  /// - Must end with a number
  /// - Operators must be followed by numbers
  /// - Numbers must be followed by operators (except at end)
  static bool _validateTokens(List<Token> tokens) {
    if (tokens.isEmpty) {
      return false;
    }

    // Must start with a number
    if (!tokens.first.isNumber) {
      return false;
    }

    // Must end with a number
    if (!tokens.last.isNumber) {
      return false;
    }

    // Check alternating pattern: number, operator, number, operator, ...
    for (int i = 0; i < tokens.length - 1; i++) {
      final Token current = tokens[i];
      final Token next = tokens[i + 1];

      if (current.isNumber && !next.isOperator) {
        return false; // Number must be followed by operator
      }
      if (current.isOperator && !next.isNumber) {
        return false; // Operator must be followed by number
      }
    }

    return true;
  }

  /// Evaluates tokens with operator precedence.
  ///
  /// Algorithm:
  /// 1. Process all multiplication and division (left to right)
  /// 2. Process all addition and subtraction (left to right)
  static double? _evaluateWithPrecedence(List<Token> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    // Single number
    if (tokens.length == 1) {
      return tokens.first.value;
    }

    // Step 1: Process multiplication and division (left to right)
    final List<Token> afterMulDiv = <Token>[];
    double? currentValue = tokens.first.value;

    for (int i = 1; i < tokens.length; i += 2) {
      if (i + 1 >= tokens.length) {
        break; // Should not happen if validated
      }

      final String operator = tokens[i].operator!;
      final double nextValue = tokens[i + 1].value!;

      if (operator == '*' || operator == '/') {
        if (operator == '*') {
          currentValue = currentValue! * nextValue;
        } else {
          // Division
          if (nextValue == 0) {
            _log.warning('Division by zero detected');
            return null;
          }
          currentValue = currentValue! / nextValue;
        }
      } else {
        // Addition or subtraction - save for step 2
        afterMulDiv.add(Token.number(currentValue));
        afterMulDiv.add(Token.operator(operator));
        currentValue = nextValue;
      }
    }

    // Add final value
    afterMulDiv.add(Token.number(currentValue));

    // Step 2: Process addition and subtraction (left to right)
    if (afterMulDiv.length == 1) {
      return afterMulDiv.first.value;
    }

    double? result = afterMulDiv.first.value;
    for (int i = 1; i < afterMulDiv.length; i += 2) {
      if (i + 1 >= afterMulDiv.length) {
        break;
      }

      final String operator = afterMulDiv[i].operator!;
      final double nextValue = afterMulDiv[i + 1].value!;

      if (operator == '+') {
        result = result! + nextValue;
      } else if (operator == '-') {
        result = result! - nextValue;
      }
    }

    return result;
  }

  /// Checks if a character is a digit.
  static bool _isDigit(String char) {
    return char.length == 1 &&
        char.codeUnitAt(0) >= 48 &&
        char.codeUnitAt(0) <= 57;
  }

  /// Checks if a character is an operator.
  static bool _isOperator(String char) {
    return char == '+' || char == '-' || char == '*' || char == '/';
  }
}

/// Token representing either a number or an operator in an expression.
class Token {
  const Token.number(this.value) : operator = null;
  const Token.operator(this.operator) : value = null;

  final double? value;
  final String? operator;

  bool get isNumber => value != null;
  bool get isOperator => operator != null;

  @override
  String toString() {
    if (isNumber) {
      return 'Token.number($value)';
    } else {
      return 'Token.operator("$operator")';
    }
  }
}
