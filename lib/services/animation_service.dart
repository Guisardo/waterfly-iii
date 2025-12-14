import 'package:flutter/material.dart';

/// Service providing consistent animations across offline mode features.
///
/// Follows Material 3 motion guidelines:
/// - Standard easing curves
/// - Appropriate durations
/// - Smooth state transitions
class AnimationService {
  static final AnimationService _instance = AnimationService._internal();
  factory AnimationService() => _instance;
  AnimationService._internal();

  // Standard durations (Material 3)
  static const Duration short1 = Duration(milliseconds: 50);
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium3 = Duration(milliseconds: 350);
  static const Duration medium4 = Duration(milliseconds: 400);
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);

  // Standard curves (Material 3)
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve emphasizedDecelerate = Curves.easeOutCubic;
  static const Curve emphasizedAccelerate = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOut;
  static const Curve standardDecelerate = Curves.easeOut;
  static const Curve standardAccelerate = Curves.easeIn;

  /// Fade transition for connectivity status changes
  Widget buildConnectivityTransition({
    required Widget child,
    required bool isOnline,
  }) {
    return AnimatedSwitcher(
      duration: medium2,
      switchInCurve: emphasizedDecelerate,
      switchOutCurve: emphasizedAccelerate,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: emphasizedDecelerate,
            )),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Sync progress animation
  Widget buildSyncProgressAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: emphasizedDecelerate),
        ),
        child: child,
      ),
    );
  }

  /// Pulse animation for syncing indicator
  Animation<double> createPulseAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  /// Shimmer effect for loading states
  Widget buildShimmerEffect({
    required Widget child,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.0),
              ],
              stops: [
                controller.value - 0.3,
                controller.value,
                controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Success animation (checkmark)
  Widget buildSuccessAnimation({
    required AnimationController controller,
    Color? color,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      ),
      child: Icon(
        Icons.check_circle,
        color: color ?? Colors.green,
        size: 48,
      ),
    );
  }

  /// Error animation (shake)
  Widget buildErrorAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    final animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticIn,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            animation.value * (controller.value < 0.5 ? 1 : -1),
            0,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// List item appearance animation
  Widget buildListItemAnimation({
    required Widget child,
    required int index,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            1.0,
            curve: emphasizedDecelerate,
          ),
        )),
        child: child,
      ),
    );
  }

  /// Dialog appearance animation
  Widget buildDialogAnimation({
    required BuildContext context,
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: emphasizedDecelerate,
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: emphasizedDecelerate,
          ),
        ),
        child: child,
      ),
    );
  }

  /// Bottom sheet slide animation
  Widget buildBottomSheetAnimation({
    required Animation<double> animation,
    required Widget child,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: emphasizedDecelerate,
      )),
      child: child,
    );
  }

  /// Rotation animation for refresh icon
  Widget buildRotationAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    return RotationTransition(
      turns: controller,
      child: child,
    );
  }

  /// Smooth color transition
  Animation<Color?> createColorAnimation({
    required AnimationController controller,
    required Color begin,
    required Color end,
  }) {
    return ColorTween(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: standard),
    );
  }

  /// Page transition builder
  Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: emphasizedDecelerate,
        )),
        child: child,
      ),
    );
  }
}

/// Mixin for widgets that need animation controllers
mixin AnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  // Reserved for future centralized animation management
  // ignore: unused_field
  final AnimationService _animationService = AnimationService();
  final Map<String, AnimationController> _controllers = {};

  /// Create and register an animation controller
  AnimationController createController({
    required String key,
    required Duration duration,
    Duration? reverseDuration,
  }) {
    final controller = AnimationController(
      vsync: this,
      duration: duration,
      reverseDuration: reverseDuration,
    );
    _controllers[key] = controller;
    return controller;
  }

  /// Get registered controller
  AnimationController? getController(String key) => _controllers[key];

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
