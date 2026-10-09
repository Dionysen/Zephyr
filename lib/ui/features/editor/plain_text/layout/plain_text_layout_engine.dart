import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show TextSelection;

import '../../../../../domain/models/editor_margins.dart';
import '../document/plain_text_document.dart';
import 'editor_typography.dart';
import 'paragraph_layout_cache.dart';
import 'paragraph_metrics.dart';

/// Lays out a [PlainTextDocument] paragraph-by-paragraph with independent
/// line height and paragraph spacing.
class PlainTextLayoutEngine {
  PlainTextLayoutEngine();

  final ParagraphLayoutCache _cache = ParagraphLayoutCache();

  PlainTextDocument _document = PlainTextDocument.empty;
  EditorTypography _typography = const EditorTypography(
    color: Color(0xFF000000),
    fontSize: 18,
    lineHeight: 1.75,
    paragraphSpacing: 0.5,
    marginLeft: 24,
    marginRight: 24,
  );
  double _viewportWidth = 760;

  List<ParagraphMetrics> _metrics = const [];
  double _contentWidth = 0;
  double _contentLeft = 0;
  double _totalHeight = 0;
  List<int> _paragraphStarts = const [];

  PlainTextDocument get document => _document;
  EditorTypography get typography => _typography;
  double get totalHeight => _totalHeight;
  double get contentWidth => _contentWidth;
  List<ParagraphMetrics> get metrics => _metrics;

  /// Left edge of the text column inside the viewport (resolved margin).
  double get contentLeft => _contentLeft;

  EditorMargins _resolveMargins() => EditorMargins.resolve(
    viewportWidth: _viewportWidth,
    desiredLeft: _typography.marginLeft,
    desiredRight: _typography.marginRight,
    minContentWidth: math.max(120.0, _typography.fontSize * 8),
  );

  void dispose() {
    _metrics = const [];
    _cache.dispose();
  }

  void update({
    required PlainTextDocument document,
    required EditorTypography typography,
    required double viewportWidth,
  }) {
    final widthChanged =
        viewportWidth != _viewportWidth || typography != _typography;
    final textChanged = document.text != _document.text;
    _document = document;
    _typography = typography;
    _viewportWidth = viewportWidth;
    if (widthChanged || textChanged || _metrics.isEmpty) {
      _relayoutAll();
    }
  }

  void _relayoutAll() {
    final paras = _document.paragraphs;
    _paragraphStarts = _document.paragraphStarts();
    final margins = _resolveMargins();
    _contentLeft = margins.left;
    final maxTextWidth = math.max(1.0, margins.contentWidth);
    _contentWidth = maxTextWidth;

    final next = <ParagraphMetrics>[];
    var y = _typography.paddingTop;
    for (var i = 0; i < paras.length; i++) {
      final text = paras[i];
      final painter = _cache.painterFor(
        text: text,
        typography: _typography,
        maxWidth: maxTextWidth,
      );
      final contentHeight = math.max(
        painter.height,
        _typography.fontSize * _typography.lineHeight,
      );
      final gap = i < paras.length - 1 ? _typography.paragraphGap : 0.0;
      next.add(
        ParagraphMetrics(
          index: i,
          text: text,
          startOffset: _paragraphStarts[i],
          yOffset: y,
          contentHeight: contentHeight,
          gapAfter: gap,
          painter: painter,
        ),
      );
      y += contentHeight + gap;
    }
    y += _typography.paddingBottom;
    _metrics = next;
    _totalHeight = y;

    final keep = paras.toSet();
    _cache.retainOnly(keep);
  }

  /// Inclusive range of paragraph indices intersecting [scrollOffset, scrollOffset+viewportHeight].
  (int, int) visibleParagraphRange({
    required double scrollOffset,
    required double viewportHeight,
    double overscan = 0,
  }) {
    if (_metrics.isEmpty) return (0, -1);
    final top = scrollOffset - overscan;
    final bottom = scrollOffset + viewportHeight + overscan;
    var first = 0;
    var last = _metrics.length - 1;
    // Binary search first visible.
    var lo = 0;
    var hi = _metrics.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final m = _metrics[mid];
      if (m.endY < top) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
        first = mid;
      }
    }
    lo = first;
    hi = _metrics.length - 1;
    last = first;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final m = _metrics[mid];
      if (m.yOffset > bottom) {
        hi = mid - 1;
      } else {
        last = mid;
        lo = mid + 1;
      }
    }
    return (first.clamp(0, _metrics.length - 1), last.clamp(0, _metrics.length - 1));
  }

  int offsetForPosition(Offset documentLocal) {
    if (_metrics.isEmpty) return 0;
    final x = documentLocal.dx - contentLeft;
    final y = documentLocal.dy;
    ParagraphMetrics? target;
    for (final m in _metrics) {
      if (y < m.endY) {
        target = m;
        break;
      }
    }
    target ??= _metrics.last;
    final local = Offset(x.clamp(0.0, _contentWidth), (y - target.yOffset).clamp(0.0, target.contentHeight));
    final pos = target.painter.getPositionForOffset(local);
    var offset = target.startOffset + pos.offset;
    // Empty paragraph laid out as '' — caret at start.
    if (target.text.isEmpty) {
      offset = target.startOffset;
    }
    return offset.clamp(0, _document.length);
  }

  Rect? caretRectForOffset(int offset) {
    if (_metrics.isEmpty) return null;
    final clamped = offset.clamp(0, _document.length);
    final index = _document.paragraphIndexForOffset(clamped);
    final m = _metrics[index];
    final localOffset = (clamped - m.startOffset).clamp(0, m.text.length);
    final caret = m.painter.getOffsetForCaret(
      TextPosition(offset: localOffset),
      Rect.zero,
    );
    final height = m.painter.preferredLineHeight;
    return Rect.fromLTWH(
      contentLeft + caret.dx,
      m.yOffset + caret.dy,
      2,
      height,
    );
  }

  List<Rect> boxesForSelection(TextSelection selection) {
    if (selection.isCollapsed || _metrics.isEmpty) return const [];
    final start = selection.start.clamp(0, _document.length);
    final end = selection.end.clamp(0, _document.length);
    if (start >= end) return const [];

    final boxes = <Rect>[];
    for (final m in _metrics) {
      final paraStart = m.startOffset;
      final paraEnd = m.endOffset;
      final selStart = math.max(start, paraStart);
      final selEnd = math.min(end, paraEnd);
      if (selStart >= selEnd && !(m.text.isEmpty && start <= paraStart && end > paraStart)) {
        // Selection covering the newline after this paragraph still paints nothing here.
        continue;
      }
      if (m.text.isEmpty) {
        if (start <= paraStart && end > paraStart) {
          boxes.add(
            Rect.fromLTWH(
              contentLeft,
              m.yOffset,
              4,
              m.contentHeight,
            ),
          );
        }
        continue;
      }
      final localStart = selStart - paraStart;
      final localEnd = selEnd - paraStart;
      final textBoxes = m.painter.getBoxesForSelection(
        TextSelection(baseOffset: localStart, extentOffset: localEnd),
      );
      for (final box in textBoxes) {
        boxes.add(
          Rect.fromLTRB(
            contentLeft + box.left,
            m.yOffset + box.top,
            contentLeft + box.right,
            m.yOffset + box.bottom,
          ),
        );
      }
    }
    return boxes;
  }

  /// Line boxes for an arbitrary document range (decorations).
  List<Rect> boxesForRange(int start, int end) {
    return boxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );
  }
}
