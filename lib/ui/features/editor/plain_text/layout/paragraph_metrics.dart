import 'package:flutter/painting.dart';

/// Laid-out metrics for a single paragraph.
class ParagraphMetrics {
  ParagraphMetrics({
    required this.index,
    required this.text,
    required this.startOffset,
    required this.yOffset,
    required this.contentHeight,
    required this.gapAfter,
    required this.painter,
  });

  final int index;
  final String text;

  /// UTF-16 start of this paragraph in the full document.
  final int startOffset;

  /// Top of this paragraph in document coordinates.
  final double yOffset;

  /// Height of the laid-out text (no trailing paragraph gap).
  final double contentHeight;

  /// Extra space after this paragraph toward the next one.
  final double gapAfter;

  final TextPainter painter;

  double get totalHeight => contentHeight + gapAfter;

  double get endY => yOffset + totalHeight;

  int get endOffset => startOffset + text.length;

  void dispose() {
    painter.dispose();
  }
}
