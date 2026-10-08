import 'package:flutter/services.dart';

/// Helpers around [TextSelection] for the plain-text engine.
extension PlainTextSelectionX on TextSelection {
  TextSelection clampedTo(int length) {
    final base = baseOffset.clamp(0, length);
    final extent = extentOffset.clamp(0, length);
    return copyWith(baseOffset: base, extentOffset: extent);
  }

  /// Extends or moves the extent to [offset], keeping base when selecting.
  TextSelection withExtentAt(int offset, {required bool selecting}) {
    if (selecting) {
      return TextSelection(
        baseOffset: baseOffset,
        extentOffset: offset,
        affinity: affinity,
      );
    }
    return TextSelection.collapsed(offset: offset, affinity: affinity);
  }
}

int clampOffset(int offset, int length) => offset.clamp(0, length);
