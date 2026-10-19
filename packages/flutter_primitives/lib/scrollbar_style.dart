import 'package:flutter/material.dart';

/// Scrollbar chrome aligned with [editor scrollbar] / the plain-text editor.
abstract final class ScrollbarStyle {
  /// Barely lighter than the editor surface — one color, no active state.
  static Color editorThumbColor(ColorScheme scheme) {
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      scheme.surface,
    );
  }

  /// Arrow / affordance on the mobile editor thumb.
  static Color editorThumbArrowColor(ColorScheme scheme) {
    return scheme.onSurface.withValues(alpha: 0.40);
  }

  /// Horizontal code-block track: match editor thumb thickness feel.
  static const double horizontalThumbThickness = 6;
}
