import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Service for managing visual accessibility features.
///
/// Provides:
/// - Color contrast validation (WCAG AA/AAA compliance)
/// - Text scaling support
/// - Icon with text label combinations
/// - High contrast mode detection
/// - Color-independent information display
///
/// Example:
/// ```dart
/// final visualService = VisualAccessibilityService();
/// final hasGoodContrast = visualService.checkContrast(
///   foreground: Colors.white,
///   background: Colors.blue,
/// );
/// ```
class VisualAccessibilityService {
  static final Logger _logger = Logger('VisualAccessibilityService');
  static final VisualAccessibilityService _instance = VisualAccessibilityService._internal();

  factory VisualAccessibilityService() => _instance;

  VisualAccessibilityService._internal();

  /// Check if color combination meets WCAG AA contrast requirements (4.5:1 for normal text)
  bool checkContrast({
    required Color foreground,
    required Color background,
    bool largeText = false,
  }) {
    final contrast = calculateContrastRatio(foreground, background);
    final requiredRatio = largeText ? 3.0 : 4.5;
    
    final meetsRequirement = contrast >= requiredRatio;
    
    if (!meetsRequirement) {
      _logger.warning(
        'Insufficient contrast: $contrast:1 (required: $requiredRatio:1) '
        'for ${foreground.value.toRadixString(16)} on ${background.value.toRadixString(16)}',
      );
    }
    
    return meetsRequirement;
  }

  /// Check if color combination meets WCAG AAA contrast requirements (7:1 for normal text)
  bool checkContrastAAA({
    required Color foreground,
    required Color background,
    bool largeText = false,
  }) {
    final contrast = calculateContrastRatio(foreground, background);
    final requiredRatio = largeText ? 4.5 : 7.0;
    
    return contrast >= requiredRatio;
  }

  /// Calculate contrast ratio between two colors
  double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Get accessible color for text on given background
  Color getAccessibleTextColor(Color background) {
    final luminance = background.computeLuminance();
    
    // Use white text on dark backgrounds, black on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Build icon with text label for accessibility
  Widget buildIconWithLabel({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color? iconColor,
    double? iconSize,
    TextStyle? textStyle,
    MainAxisAlignment alignment = MainAxisAlignment.center,
    double spacing = 4.0,
  }) {
    final effectiveIconColor = iconColor ?? Theme.of(context).colorScheme.onSurface;
    final effectiveTextStyle = textStyle ?? Theme.of(context).textTheme.labelSmall;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Icon(
          icon,
          color: effectiveIconColor,
          size: iconSize,
        ),
        SizedBox(height: spacing),
        Text(
          label,
          style: effectiveTextStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build status indicator with both color and icon (not relying solely on color)
  Widget buildAccessibleStatusIndicator({
    required BuildContext context,
    required String status,
    required IconData icon,
    required Color color,
    String? label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label ?? status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }

  /// Validate theme colors for accessibility
  Map<String, bool> validateThemeColors(ColorScheme colorScheme) {
    final results = <String, bool>{};
    
    // Check primary text on primary background
    results['primary_text'] = checkContrast(
      foreground: colorScheme.onPrimary,
      background: colorScheme.primary,
    );
    
    // Check secondary text on secondary background
    results['secondary_text'] = checkContrast(
      foreground: colorScheme.onSecondary,
      background: colorScheme.secondary,
    );
    
    // Check surface text on surface background
    results['surface_text'] = checkContrast(
      foreground: colorScheme.onSurface,
      background: colorScheme.surface,
    );
    
    // Check error text on error background
    results['error_text'] = checkContrast(
      foreground: colorScheme.onError,
      background: colorScheme.error,
    );
    
    // Check body text on background
    results['body_text'] = checkContrast(
      foreground: colorScheme.onSurface,
      background: colorScheme.surface,
    );
    
    final failedChecks = results.entries.where((e) => !e.value).map((e) => e.key).toList();
    
    if (failedChecks.isNotEmpty) {
      _logger.warning('Theme color contrast issues: ${failedChecks.join(", ")}');
    } else {
      _logger.info('All theme colors meet WCAG AA contrast requirements');
    }
    
    return results;
  }

  /// Get recommended text size multiplier based on accessibility settings
  double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Check if large text is enabled
  bool isLargeTextEnabled(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor > 1.0;
  }

  /// Build text with minimum size for accessibility
  Widget buildAccessibleText({
    required String text,
    required BuildContext context,
    TextStyle? style,
    double minFontSize = 12.0,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final textScaleFactor = getTextScaleFactor(context);
    final effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final baseFontSize = effectiveStyle?.fontSize ?? 14.0;
    final scaledFontSize = baseFontSize * textScaleFactor;
    
    // Ensure minimum font size
    final finalFontSize = scaledFontSize < minFontSize ? minFontSize : scaledFontSize;
    
    return Text(
      text,
      style: effectiveStyle?.copyWith(fontSize: finalFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Build button with sufficient touch target size (minimum 48x48 dp)
  Widget buildAccessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    double minWidth = 48.0,
    double minHeight = 48.0,
    EdgeInsets? padding,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding ?? const EdgeInsets.all(12),
        ),
        child: child,
      ),
    );
  }

  /// Check if high contrast mode is enabled (platform-specific)
  bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get accessible color scheme for high contrast mode
  ColorScheme getHighContrastColorScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        error: Colors.red.shade300,
        onError: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      );
    } else {
      return ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        error: Colors.red.shade900,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
    }
  }

  /// Log accessibility warnings for development
  void logAccessibilityWarnings(BuildContext context, ColorScheme colorScheme) {
    if (!kDebugMode) return;
    
    _logger.info('=== Accessibility Check ===');
    _logger.info('Text scale factor: ${getTextScaleFactor(context)}');
    _logger.info('High contrast mode: ${isHighContrastEnabled(context)}');
    
    final validationResults = validateThemeColors(colorScheme);
    final failedChecks = validationResults.entries.where((e) => !e.value).length;
    
    if (failedChecks > 0) {
      _logger.warning('$failedChecks color contrast checks failed');
    } else {
      _logger.info('All color contrast checks passed');
    }
    
    _logger.info('=========================');
  }
}

/// Widget that ensures minimum touch target size
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;

  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: child,
    );
  }
}

/// Extension for checking if running in debug mode
extension on VisualAccessibilityService {
  bool get kDebugMode {
    bool debugMode = false;
    assert(() {
      debugMode = true;
      return true;
    }());
    return debugMode;
  }
}
