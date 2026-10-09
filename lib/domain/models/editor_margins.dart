import 'dart:math' as math;

/// Resolved horizontal margins for the reading column.
class EditorMargins {
  const EditorMargins({
    required this.left,
    required this.right,
    required this.contentWidth,
  });

  final double left;
  final double right;
  final double contentWidth;

  /// Places content between [desiredLeft] and [desiredRight].
  ///
  /// When the viewport is too narrow for the desired margins plus
  /// [minContentWidth], both margins shrink by the same scale factor so their
  /// ratio is preserved. If the desires are equal, the resolved values are
  /// identical (never split leftover independently).
  static EditorMargins resolve({
    required double viewportWidth,
    required double desiredLeft,
    required double desiredRight,
    double minContentWidth = 120,
  }) {
    final viewport = math.max(0.0, viewportWidth);
    final minContent = math.min(minContentWidth, viewport).clamp(0.0, viewport);
    final wantLeft = math.max(0.0, desiredLeft);
    final wantRight = math.max(0.0, desiredRight);
    final wantSum = wantLeft + wantRight;
    final equal = wantLeft == wantRight;

    if (wantSum + minContent <= viewport + 1e-9) {
      if (equal) {
        // Single value so float noise cannot make sides differ.
        final each = wantLeft;
        return EditorMargins(
          left: each,
          right: each,
          contentWidth: viewport - 2 * each,
        );
      }
      return EditorMargins(
        left: wantLeft,
        right: wantRight,
        contentWidth: viewport - wantSum,
      );
    }

    final avail = math.max(0.0, viewport - minContent);
    if (wantSum <= 1e-9) {
      return EditorMargins(left: 0, right: 0, contentWidth: viewport);
    }
    if (equal) {
      final each = avail / 2;
      return EditorMargins(
        left: each,
        right: each,
        contentWidth: viewport - avail,
      );
    }
    final scale = avail / wantSum;
    return EditorMargins(
      left: wantLeft * scale,
      right: wantRight * scale,
      contentWidth: viewport - avail,
    );
  }
}
