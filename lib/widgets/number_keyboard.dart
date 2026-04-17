import 'package:flutter/material.dart';

typedef NumberKeyCallback = void Function(String value);

/// A custom on-screen numeric keyboard with mathematical operator buttons.
///
/// Displays a calculator-style keypad:
/// ```
/// [C]  [⌫]  [%]  [÷]
/// [7]  [8]  [9]  [×]
/// [4]  [5]  [6]  [−]
/// [1]  [2]  [3]  [+]
/// [.]  [0]       [=]
/// ```
///
/// Used by [NumberInput] when [NumberInput.showMathKeyboard] is true to
/// replace the system keyboard with one that exposes arithmetic operators.
class NumberKeyboard extends StatelessWidget {
  const NumberKeyboard({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onEquals,
    required this.onPercent,
    this.hasDecimal = true,
  });

  /// Called when a digit, decimal point, or operator key is pressed.
  /// The [value] is the character to insert (e.g. '7', '+', '/').
  final NumberKeyCallback onKey;

  /// Called when the backspace key is pressed.
  final VoidCallback onBackspace;

  /// Called when the C (clear) key is pressed.
  final VoidCallback onClear;

  /// Called when the = (equals) key is pressed to evaluate and dismiss.
  final VoidCallback onEquals;

  /// Called when the % key is pressed to apply percentage conversion.
  final VoidCallback onPercent;

  /// Whether to show the decimal point key. Set to false when [NumberInput.decimals] is 0.
  final bool hasDecimal;

  static const double _keyHeight = 56.0;
  static const double _spacing = 4.0;

  Widget _digitKey(BuildContext context, String label, String value) {
    return Expanded(
      child: SizedBox(
        height: _keyHeight,
        child: FilledButton.tonal(
          onPressed: () => onKey(value),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }

  Widget _operatorKey(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: SizedBox(
        height: _keyHeight,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }

  Widget _clearKey(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: _keyHeight,
        child: FilledButton(
          onPressed: onClear,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('C', style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }

  Widget _backspaceKey(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: _keyHeight,
        child: FilledButton(
          onPressed: onBackspace,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.backspace_outlined),
        ),
      ),
    );
  }

  Widget _equalsKey(BuildContext context) {
    return Expanded(
      flex: 2,
      child: SizedBox(
        height: _keyHeight,
        child: FilledButton(
          onPressed: onEquals,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('=', style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Row 1: C  ⌫  %  ÷
            Row(
              children: <Widget>[
                _clearKey(context),
                const SizedBox(width: _spacing),
                _backspaceKey(context),
                const SizedBox(width: _spacing),
                _operatorKey(context, '%', onPercent),
                const SizedBox(width: _spacing),
                _operatorKey(context, '÷', () => onKey('/')),
              ],
            ),
            const SizedBox(height: _spacing),
            // Row 2: 7  8  9  ×
            Row(
              children: <Widget>[
                _digitKey(context, '7', '7'),
                const SizedBox(width: _spacing),
                _digitKey(context, '8', '8'),
                const SizedBox(width: _spacing),
                _digitKey(context, '9', '9'),
                const SizedBox(width: _spacing),
                _operatorKey(context, '×', () => onKey('*')),
              ],
            ),
            const SizedBox(height: _spacing),
            // Row 3: 4  5  6  −
            Row(
              children: <Widget>[
                _digitKey(context, '4', '4'),
                const SizedBox(width: _spacing),
                _digitKey(context, '5', '5'),
                const SizedBox(width: _spacing),
                _digitKey(context, '6', '6'),
                const SizedBox(width: _spacing),
                _operatorKey(context, '−', () => onKey('-')),
              ],
            ),
            const SizedBox(height: _spacing),
            // Row 4: 1  2  3  +
            Row(
              children: <Widget>[
                _digitKey(context, '1', '1'),
                const SizedBox(width: _spacing),
                _digitKey(context, '2', '2'),
                const SizedBox(width: _spacing),
                _digitKey(context, '3', '3'),
                const SizedBox(width: _spacing),
                _operatorKey(context, '+', () => onKey('+')),
              ],
            ),
            const SizedBox(height: _spacing),
            // Row 5: [.]  [0]  [= =]
            Row(
              children: <Widget>[
                hasDecimal
                    ? _digitKey(context, '.', '.')
                    : const Expanded(child: SizedBox(height: _keyHeight)),
                const SizedBox(width: _spacing),
                _digitKey(context, '0', '0'),
                const SizedBox(width: _spacing),
                _equalsKey(context),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
