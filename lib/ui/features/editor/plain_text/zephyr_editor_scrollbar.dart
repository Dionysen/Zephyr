import 'dart:async';

import 'package:flutter/material.dart';

/// Editor scrollbar with a fixed-size major-arc circular thumb.
///
/// Scroll mapping matches a normal vertical scrollbar (thumb position ↔
/// [ScrollPosition.pixels]); only the chrome differs — the thumb does not
/// grow or shrink with document length.
class ZephyrEditorScrollbar extends StatefulWidget {
  const ZephyrEditorScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.thumbExtent = 36,
    this.mainAxisMargin = 8,
    this.padding = EdgeInsets.zero,
  });

  final ScrollController controller;
  final Widget child;

  /// Fixed thumb height (circle diameter).
  final double thumbExtent;

  /// Inset from the top/bottom of the track (inside [padding]).
  final double mainAxisMargin;

  /// Outer inset for the track — e.g. top padding below a floating app bar.
  final EdgeInsets padding;

  /// How much of the diameter protrudes into the document (rest is clipped).
  static const double visibleDiameterFraction = 2 / 3;

  /// Visible width = [visibleDiameterFraction] of the diameter.
  double get thumbThickness => thumbExtent * visibleDiameterFraction;

  @override
  State<ZephyrEditorScrollbar> createState() => _ZephyrEditorScrollbarState();
}

class _ZephyrEditorScrollbarState extends State<ZephyrEditorScrollbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _fadeTimer;
  bool _dragging = false;
  double _dragThumbTop = 0;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(ZephyrEditorScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    widget.controller.removeListener(_onScroll);
    _fade.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {});
    _showThumb();
  }

  void _showThumb() {
    _fade.forward();
    _fadeTimer?.cancel();
    if (_dragging) return;
    _fadeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && !_dragging) {
        _fade.reverse();
      }
    });
  }

  ScrollPosition? get _position {
    final c = widget.controller;
    if (!c.hasClients) return null;
    return c.position;
  }

  bool get _scrollable {
    final position = _position;
    return position != null && position.maxScrollExtent > 0.5;
  }

  double _trackMin(double viewport) =>
      widget.padding.top + widget.mainAxisMargin;

  double _trackMax(double viewport) =>
      viewport - widget.padding.bottom - widget.mainAxisMargin;

  double _trackExtent(double viewport) =>
      (_trackMax(viewport) - _trackMin(viewport) - widget.thumbExtent).clamp(
        0.0,
        double.infinity,
      );

  double _thumbTopForPixels(ScrollPosition position, double viewport) {
    final min = _trackMin(viewport);
    final track = _trackExtent(viewport);
    if (track <= 0 || position.maxScrollExtent <= 0) {
      return min;
    }
    final t = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    return min + t * track;
  }

  void _jumpThumbTo(double thumbTop, double viewport) {
    final position = _position;
    if (position == null) return;
    final min = _trackMin(viewport);
    final track = _trackExtent(viewport);
    if (track <= 0) return;
    final t = ((thumbTop - min) / track).clamp(0.0, 1.0);
    position.jumpTo(t * position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Barely lighter than the editor surface — one color, no active state.
    final surface = theme.colorScheme.surface;
    final color = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.08),
      surface,
    );
    final arrow = theme.colorScheme.onSurface.withValues(alpha: 0.40);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) return false;
        _showThumb();
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxHeight;
          final position = _position;
          final show = _scrollable && viewport.isFinite && viewport > 0;
          final thumbTop = !show
              ? 0.0
              : _dragging
              ? _dragThumbTop
              : _thumbTopForPixels(position!, viewport);
          final thickness = widget.thumbThickness;
          // Wider than the paint so the semicircle is easy to grab.
          final hitWidth = thickness + 12;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              if (show)
                Positioned(
                  right: 0,
                  top: thumbTop,
                  width: hitWidth,
                  height: widget.thumbExtent,
                  child: AnimatedBuilder(
                    animation: _fade,
                    builder: (context, child) => IgnorePointer(
                      // Fully faded thumbs must not steal edge taps/scrolls.
                      ignoring: !_dragging && _fade.value < 0.01,
                      child: Opacity(opacity: _fade.value, child: child),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) {
                        _dragging = true;
                        _dragThumbTop = thumbTop;
                        _fadeTimer?.cancel();
                        _fade.forward();
                      },
                      onVerticalDragUpdate: (details) {
                        final min = _trackMin(viewport);
                        final track = _trackExtent(viewport);
                        final next = (_dragThumbTop + details.delta.dy).clamp(
                          min,
                          min + track,
                        );
                        _dragThumbTop = next;
                        _jumpThumbTo(next, viewport);
                        setState(() {});
                      },
                      onVerticalDragEnd: (_) {
                        _dragging = false;
                        _showThumb();
                      },
                      onVerticalDragCancel: () {
                        _dragging = false;
                        _showThumb();
                      },
                      child: Align(
                        alignment: Alignment.centerRight,
                        // No ClipRect here — soft shadow is allowed to spill left.
                        child: CustomPaint(
                          size: Size(thickness, widget.thumbExtent),
                          painter: _SemicircleThumbPainter(
                            color: color,
                            arrowColor: arrow,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Circle clipped to [size]: right side cut away so the chord sits on the
/// screen edge and the arc bulges into the document (⅔ of the diameter).
class _SemicircleThumbPainter extends CustomPainter {
  const _SemicircleThumbPainter({
    required this.color,
    required this.arrowColor,
  });

  final Color color;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final radius = size.height / 2;
    // Left tip of the circle at x=0; right of the circle past [size.width]
    // is clipped — the cut face is flush with the screen’s right edge.
    final center = Offset(radius, radius);
    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Soft drop shadow may spill left of the thumb bounds.
    canvas.drawShadow(
      circle,
      Colors.black.withValues(alpha: 0.55),
      3.5,
      true,
    );

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(circle, fill);

    // Center arrows in the remaining (clipped) width, not the full circle.
    final arrowX = size.width / 2;
    const arrow = 4.0;
    const gap = 5.5;
    _drawTriangle(
      canvas,
      tip: Offset(arrowX, center.dy - gap),
      size: arrow,
      up: true,
    );
    _drawTriangle(
      canvas,
      tip: Offset(arrowX, center.dy + gap),
      size: arrow,
      up: false,
    );
    canvas.restore();
  }

  void _drawTriangle(
    Canvas canvas, {
    required Offset tip,
    required double size,
    required bool up,
  }) {
    final path = Path();
    final half = size * 0.75;
    if (up) {
      path
        ..moveTo(tip.dx, tip.dy - size * 0.55)
        ..lineTo(tip.dx - half, tip.dy + size * 0.45)
        ..lineTo(tip.dx + half, tip.dy + size * 0.45);
    } else {
      path
        ..moveTo(tip.dx, tip.dy + size * 0.55)
        ..lineTo(tip.dx - half, tip.dy - size * 0.45)
        ..lineTo(tip.dx + half, tip.dy - size * 0.45);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = arrowColor);
  }

  @override
  bool shouldRepaint(covariant _SemicircleThumbPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.arrowColor != arrowColor;
}
