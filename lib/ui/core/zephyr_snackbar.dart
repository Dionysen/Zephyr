import 'package:flutter/material.dart';

import 'zephyr_theme.dart';

/// Floating toast near the bottom edge, using the app corner radius.
abstract final class ZephyrSnackBar {
  /// Gap between the floating bar and the screen / safe-area bottom.
  static const double bottomGap = 28;

  static const EdgeInsets insetPadding = EdgeInsets.fromLTRB(
    16,
    8,
    16,
    bottomGap,
  );

  /// Shows a short floating message. Clears any snack bar already on screen.
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(build(context, message, action: action, duration: duration));
  }

  /// Builds a snack bar that matches Zephyr chrome (callers rarely need this).
  static SnackBar build(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Match the shell: white bar in light mode, black bar in dark mode.
    final background = isDark ? Colors.black : Colors.white;
    final foreground = isDark ? Colors.white : Colors.black87;
    return SnackBar(
      content: Text(
        message,
        style: TextStyle(color: foreground),
      ),
      action: action,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      margin: insetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: context.zephyrBorderRadius,
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(
            alpha: isDark ? 0.35 : 0.18,
          ),
        ),
      ),
      backgroundColor: background,
      dismissDirection: DismissDirection.down,
    );
  }
}
