import 'package:flutter/painting.dart';

import 'editor_typography.dart';

/// Creates and caches [TextPainter]s for paragraph strings.
class ParagraphLayoutCache {
  ParagraphLayoutCache();

  final Map<String, TextPainter> _painters = {};
  EditorTypography? _typography;
  double? _maxWidth;

  TextPainter painterFor({
    required String text,
    required EditorTypography typography,
    required double maxWidth,
  }) {
    if (_typography != typography || _maxWidth != maxWidth) {
      clear();
      _typography = typography;
      _maxWidth = maxWidth;
    }
    final existing = _painters[text];
    if (existing != null) return existing;

    final painter = TextPainter(
      text: TextSpan(text: text.isEmpty ? ' ' : text, style: typography.textStyle),
      textDirection: TextDirection.ltr,
      // Flush wrapped lines to both column edges so equal side margins read as
      // equal against the screen (last line stays start-aligned).
      textAlign: TextAlign.justify,
      strutStyle: typography.strutStyle,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);
    // Empty paragraphs still need a line box; we laid out a space then measure
    // preferred height from strut.
    if (text.isEmpty) {
      final empty = TextPainter(
        text: TextSpan(text: '', style: typography.textStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.justify,
        strutStyle: typography.strutStyle,
      )..layout(minWidth: maxWidth, maxWidth: maxWidth);
      painter.dispose();
      _painters[text] = empty;
      return empty;
    }
    _painters[text] = painter;
    return painter;
  }

  void retainOnly(Set<String> keys) {
    final stale = _painters.keys.where((k) => !keys.contains(k)).toList();
    for (final key in stale) {
      _painters.remove(key)?.dispose();
    }
  }

  void clear() {
    for (final painter in _painters.values) {
      painter.dispose();
    }
    _painters.clear();
  }

  void dispose() => clear();
}
