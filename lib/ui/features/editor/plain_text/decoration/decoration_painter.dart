import 'package:flutter/painting.dart';

import '../layout/plain_text_layout_engine.dart';
import 'text_decoration_model.dart';

void paintTextDecorations({
  required Canvas canvas,
  required PlainTextLayoutEngine engine,
  required List<TextSpanDecoration> decorations,
}) {
  for (final decoration in decorations) {
    if (decoration.start >= decoration.end) continue;
    final boxes = engine.boxesForRange(decoration.start, decoration.end);
    if (boxes.isEmpty) continue;

    for (final box in boxes) {
      final padded = box.inflate(2);
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
