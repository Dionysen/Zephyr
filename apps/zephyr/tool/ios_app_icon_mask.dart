import 'dart:ui';

/// iOS / iPadOS app-icon mask (continuous corner / squircle).
///
/// Corner radius follows Apple HIG app-icon template: ≈ 22.37% of [size].
/// Curves use a continuous-corner cubic approximation rather than circular arcs.
Path iosAppIconMask(double size) {
  final r = size * 0.2236859783094854;
  // Continuous-corner handle length (longer than circular κ·r ≈ 0.5523·r).
  final c = r * 0.64628362594;

  return Path()
    ..moveTo(r, 0)
    ..lineTo(size - r, 0)
    ..cubicTo(size - r + c, 0, size, r - c, size, r)
    ..lineTo(size, size - r)
    ..cubicTo(size, size - r + c, size - r + c, size, size - r, size)
    ..lineTo(r, size)
    ..cubicTo(r - c, size, 0, size - r + c, 0, size - r)
    ..lineTo(0, r)
    ..cubicTo(0, r - c, r - c, 0, r, 0)
    ..close();
}
