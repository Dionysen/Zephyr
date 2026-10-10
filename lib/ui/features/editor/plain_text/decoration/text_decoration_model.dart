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
    this.edgeInflate = const EdgeInsets.all(2),
    this.minEmptyWidth = 0,
    this.emptyAnchorStart,
    this.emptyAnchorEnd,
  });

  final int start;
  final int end;
  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;

  /// Extra paint padding around glyph boxes (e.g. zero horizontal for tight wraps).
  final EdgeInsets edgeInflate;

  /// When [start] == [end], paint a caret-sized placeholder at least this wide.
  final double minEmptyWidth;

  /// When the interior is empty, center the slot in the gap between the
  /// opener (`emptyAnchorStart`→`start`) and closer (`end`→`emptyAnchorEnd`)
  /// instead of at the caret (which often sits visually to the right).
  final int? emptyAnchorStart;
  final int? emptyAnchorEnd;
}
