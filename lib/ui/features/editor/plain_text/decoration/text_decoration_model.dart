import 'package:flutter/painting.dart';

/// A painted decoration over a UTF-16 range. Does not affect layout.
class TextSpanDecoration {
  const TextSpanDecoration({
    required this.start,
    required this.end,
    this.background,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = 4,
  });

  final int start;
  final int end;
  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
}
