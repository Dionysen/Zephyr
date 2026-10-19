import 'package:flutter/material.dart';

/// Shared surface + soft outer shadow used by floating bars and their menus.
class FloatingChrome extends StatelessWidget {
  const FloatingChrome({
    super.key,
    required this.borderRadius,
    required this.child,
    this.fillColor,
  });

  final BorderRadius borderRadius;
  final Widget child;

  /// When null, uses [ColorScheme.surface]. Pass [Colors.transparent] so an
  /// editor background can show through while [boxShadow] still draws.
  final Color? fillColor;

  static List<BoxShadow> shadowsFor(ColorScheme scheme) {
    final shadow = scheme.shadow;
    final dark = scheme.brightness == Brightness.dark;
    return [
      BoxShadow(
        color: shadow.withValues(alpha: dark ? 0.30 : 0.10),
        blurRadius: 14,
        offset: const Offset(0, 1.5),
      ),
      BoxShadow(
        color: shadow.withValues(alpha: dark ? 0.16 : 0.06),
        blurRadius: 5,
        offset: const Offset(0, 0.5),
      ),
      BoxShadow(
        color: shadow.withValues(alpha: dark ? 0.10 : 0.04),
        blurRadius: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = fillColor ?? theme.colorScheme.surface;
    final shadows = shadowsFor(theme.colorScheme);
    final content = Material(
      elevation: 0,
      color: fill,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
    // Transparent fill: punch the bar out of soft shadows so only the outer
    // halo remains and the editor background stays clear under the chrome.
    if (fill.a == 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _OuterBoxShadowPainter(
                borderRadius: borderRadius,
                shadows: shadows,
              ),
            ),
          ),
          content,
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: content,
    );
  }
}

/// Soft shadows that only appear outside [borderRadius] (interior punched out).
class _OuterBoxShadowPainter extends CustomPainter {
  const _OuterBoxShadowPainter({
    required this.borderRadius,
    required this.shadows,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final hole = borderRadius.toRRect(bounds);
    for (final shadow in shadows) {
      final blurSigma = shadow.blurRadius * 0.57735 + 0.5;
      final pad =
          shadow.blurRadius * 2 +
          shadow.spreadRadius.abs() +
          shadow.offset.distance;
      final layerRect = bounds.inflate(pad).shift(shadow.offset);
      canvas.saveLayer(layerRect, Paint());
      final shape = hole.shift(shadow.offset).inflate(shadow.spreadRadius);
      canvas.drawRRect(
        shape,
        Paint()
          ..color = shadow.color
          ..maskFilter = blurSigma > 0
              ? MaskFilter.blur(BlurStyle.normal, blurSigma)
              : null,
      );
      canvas.drawRRect(hole, Paint()..blendMode = BlendMode.dstOut);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OuterBoxShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.shadows != shadows;
}
