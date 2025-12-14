import 'package:flutter/material.dart';
import '../services/animation_service.dart';

/// Animated feedback widget for success/error states.
class AnimatedFeedback extends StatefulWidget {
  final bool isSuccess;
  final String message;
  final VoidCallback? onComplete;

  const AnimatedFeedback({
    super.key,
    required this.isSuccess,
    required this.message,
    this.onComplete,
  });

  @override
  State<AnimatedFeedback> createState() => _AnimatedFeedbackState();
}

class _AnimatedFeedbackState extends State<AnimatedFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AnimationService _animationService = AnimationService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationService.medium4,
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        Future.delayed(AnimationService.long1, widget.onComplete);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isSuccess)
            _animationService.buildSuccessAnimation(
              controller: _controller,
              color: Theme.of(context).colorScheme.tertiary,
            )
          else
            _animationService.buildErrorAnimation(
              controller: _controller,
              child: Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
            ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _controller,
            child: Text(
              widget.message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show animated success snackbar
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.onTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      behavior: SnackBarBehavior.floating,
      duration: AnimationService.long2,
    ),
  );
}

/// Show animated error snackbar
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.onError,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      duration: AnimationService.long2,
    ),
  );
}
