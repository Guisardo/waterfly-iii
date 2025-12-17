import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Service for managing keyboard navigation and focus for mobile accessibility.
///
/// Provides:
/// - Hardware keyboard support for tablets and external keyboards
/// - Focus management for screen readers
/// - Logical tab order for TalkBack/VoiceOver
/// - Focus indicators for accessibility
///
/// Note: Designed for mobile devices with optional hardware keyboard support.
class KeyboardNavigationService {
  static final Logger _logger = Logger('KeyboardNavigationService');
  static final KeyboardNavigationService _instance =
      KeyboardNavigationService._internal();

  factory KeyboardNavigationService() => _instance;

  KeyboardNavigationService._internal();

  /// Focus nodes for navigation
  final Map<String, FocusNode> _focusNodes = <String, FocusNode>{};

  /// Register a focus node for accessibility navigation
  void registerFocusNode(String id, FocusNode node) {
    _focusNodes[id] = node;
    _logger.fine('Registered focus node: $id');
  }

  /// Unregister a focus node
  void unregisterFocusNode(String id) {
    final FocusNode? node = _focusNodes.remove(id);
    if (node != null) {
      _logger.fine('Unregistered focus node: $id');
    }
  }

  /// Request focus for a specific node (for screen readers)
  void requestFocus(String id) {
    final FocusNode? node = _focusNodes[id];
    if (node != null) {
      node.requestFocus();
      _logger.fine('Focus requested for: $id');
    } else {
      _logger.warning('Focus node not found: $id');
    }
  }

  /// Build focus indicator decoration for accessibility
  BoxDecoration buildFocusIndicator(
    BuildContext context,
    bool hasFocus, {
    double borderWidth = 2.0,
    double borderRadius = 4.0,
  }) {
    if (!hasFocus) {
      return const BoxDecoration();
    }

    return BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// Dispose of all resources
  void dispose() {
    _logger.info('Disposing KeyboardNavigationService');

    for (final FocusNode node in _focusNodes.values) {
      node.dispose();
    }

    _focusNodes.clear();
  }
}

/// Widget that provides focus indicator for accessibility
class FocusIndicatorWidget extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? semanticLabel;

  const FocusIndicatorWidget({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 4.0,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
  });

  @override
  State<FocusIndicatorWidget> createState() => _FocusIndicatorWidgetState();
}

class _FocusIndicatorWidgetState extends State<FocusIndicatorWidget> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final KeyboardNavigationService keyboardService =
        KeyboardNavigationService();

    Widget child = Container(
      decoration: keyboardService.buildFocusIndicator(
        context,
        _hasFocus,
        borderWidth: widget.borderWidth,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );

    if (widget.semanticLabel != null) {
      child = Semantics(
        label: widget.semanticLabel,
        focused: _hasFocus,
        child: child,
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: child,
    );
  }
}
