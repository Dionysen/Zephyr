import 'package:flutter_primitives/column_resize_handle.dart';

/// Zephyr's compatibility name for the reusable column resize handle.
class ZephyrResizeHandle extends ColumnResizeHandle {
  const ZephyrResizeHandle({
    super.key,
    required super.onDragStart,
    required super.onDragUpdate,
    required super.onDragEnd,
    super.onDragCancel,
  });

  static const width = ColumnResizeHandle.width;
}
