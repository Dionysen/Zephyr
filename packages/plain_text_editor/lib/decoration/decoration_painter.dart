import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../layout/plain_text_layout_engine.dart';
import 'text_decoration_model.dart';

void paintTextDecorations({
  required Canvas canvas,
  required PlainTextLayoutEngine engine,
  required List<TextSpanDecoration> decorations,
}) {
  for (final decoration in decorations) {
    if (decoration.start > decoration.end) continue;

    final List<Rect> boxes;
    if (decoration.start == decoration.end) {
      if (decoration.minEmptyWidth <= 0) continue;
      final empty = _emptySlotBox(engine, decoration);
      if (empty == null) continue;
      boxes = [empty];
    } else {
      boxes = engine.boxesForRange(decoration.start, decoration.end);
      if (boxes.isEmpty) continue;
    }

    for (final box in boxes) {
      final pad = decoration.edgeInflate;
      var left = box.left - pad.left;
      var right = box.right + pad.right;
      // Negative horizontal inflate must not invert the rect.
      if (right <= left) {
        final mid = (box.left + box.right) / 2;
        left = mid - 0.5;
        right = mid + 0.5;
      }
      final padded = Rect.fromLTRB(
        left,
        box.top - pad.top,
        right,
        box.bottom + pad.bottom,
      );
      final rrect = RRect.fromRectAndRadius(
        padded,
        Radius.circular(decoration.borderRadius),
      );
      if (decoration.background != null) {
        canvas.drawRRect(rrect, Paint()..color = decoration.background!);
      }
      if (decoration.borderColor != null && decoration.borderWidth > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = decoration.borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = decoration.borderWidth,
        );
      }
    }
  }
}

/// Empty interior: prefer the geometric midpoint between opener and closer
/// glyphs so the frame sits visually between the pair, not on the caret.
Rect? _emptySlotBox(
  PlainTextLayoutEngine engine,
  TextSpanDecoration decoration,
) {
  final width = decoration.minEmptyWidth;
  final anchorStart = decoration.emptyAnchorStart;
  final anchorEnd = decoration.emptyAnchorEnd;
  if (anchorStart != null &&
      anchorEnd != null &&
      anchorStart < decoration.start &&
      decoration.end < anchorEnd) {
    final openBoxes = engine.boxesForRange(anchorStart, decoration.start);
    final closeBoxes = engine.boxesForRange(decoration.end, anchorEnd);
    if (openBoxes.isNotEmpty && closeBoxes.isNotEmpty) {
      final openRight = openBoxes.map((b) => b.right).reduce(math.max);
      final closeLeft = closeBoxes.map((b) => b.left).reduce(math.min);
      final openMid =
          openBoxes.map((b) => (b.left + b.right) / 2).reduce((a, b) => a + b) /
          openBoxes.length;
      final closeMid =
          closeBoxes
              .map((b) => (b.left + b.right) / 2)
              .reduce((a, b) => a + b) /
          closeBoxes.length;
      // Prefer the gap center; if glyph boxes overlap (wide bearings), fall
      // back to the midpoint between the two glyph centers.
      final midX = closeLeft > openRight
          ? (openRight + closeLeft) / 2
          : (openMid + closeMid) / 2;
      final top = math.min(
        openBoxes.map((b) => b.top).reduce(math.min),
        closeBoxes.map((b) => b.top).reduce(math.min),
      );
      final bottom = math.max(
        openBoxes.map((b) => b.bottom).reduce(math.max),
        closeBoxes.map((b) => b.bottom).reduce(math.max),
      );
      return Rect.fromCenter(
        center: Offset(midX, (top + bottom) / 2),
        width: width,
        height: math.max(bottom - top, 1),
      );
    }
  }

  final caret = engine.caretRectForOffset(decoration.start);
  if (caret == null) return null;
  return Rect.fromLTWH(
    caret.center.dx - width / 2,
    caret.top,
    width,
    caret.height,
  );
}
