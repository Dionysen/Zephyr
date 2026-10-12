import 'package:flutter/material.dart';

/// Shared column-resize grip used by the workspace (and similar) sidebars.
///
/// [onDragUpdate] receives the **cumulative** horizontal displacement from the
/// drag-start global X, not a per-frame delta. Hosts should compute
/// `startWidth + dxFromOrigin` (then clamp). That way overdragging past a
/// min/max and returning keeps the pointer aligned with the edge.
class ZephyrResizeHandle extends StatefulWidget {
  const ZephyrResizeHandle({
    super.key,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onDragCancel,
  });

  static const width = 6.0;

  final VoidCallback onDragStart;

  /// Cumulative `globalX - dragStartGlobalX` (logical px).
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback? onDragCancel;

  @override
  State<ZephyrResizeHandle> createState() => _ZephyrResizeHandleState();
}

class _ZephyrResizeHandleState extends State<ZephyrResizeHandle> {
  double? _originGlobalX;

  void _onStart(DragStartDetails details) {
    _originGlobalX = details.globalPosition.dx;
    widget.onDragStart();
  }

  void _onUpdate(DragUpdateDetails details) {
    final origin = _originGlobalX;
    if (origin == null) return;
    widget.onDragUpdate(details.globalPosition.dx - origin);
  }

  void _onEnd(DragEndDetails _) {
    _originGlobalX = null;
    widget.onDragEnd();
  }

  void _onCancel() {
    _originGlobalX = null;
    widget.onDragCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _onStart,
        onHorizontalDragUpdate: _onUpdate,
        onHorizontalDragEnd: _onEnd,
        onHorizontalDragCancel: _onCancel,
        child: SizedBox(
          width: ZephyrResizeHandle.width,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(1),
              ),
              child: const SizedBox(width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
