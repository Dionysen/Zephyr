import 'package:flutter/material.dart';

/// Shared column-resize grip used by the workspace and settings sidebars.
class ZephyrResizeHandle extends StatelessWidget {
  const ZephyrResizeHandle({
    super.key,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onDragCancel,
  });

  static const width = 6.0;

  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback? onDragCancel;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: (details) => onDragUpdate(details.delta.dx),
        onHorizontalDragEnd: (_) => onDragEnd(),
        onHorizontalDragCancel: onDragCancel,
        child: SizedBox(
          width: width,
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
