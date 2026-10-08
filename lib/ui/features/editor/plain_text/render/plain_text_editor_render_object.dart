import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../decoration/decoration_painter.dart';
import '../decoration/text_decoration_model.dart';
import '../input/plain_text_editing_controller.dart';
import '../layout/editor_typography.dart';
import '../layout/plain_text_layout_engine.dart';

/// Leaf render object that paints a virtualized plain-text document.
class PlainTextEditorRenderObject extends RenderBox {
  PlainTextEditorRenderObject({
    required PlainTextEditingController controller,
    required PlainTextLayoutEngine engine,
    required EditorTypography typography,
    required Color cursorColor,
    required Color selectionColor,
    required bool showCaret,
    required bool readOnly,
    required List<TextSpanDecoration> decorations,
    required double viewportHeight,
    required double scrollOffset,
  }) : _controller = controller,
       _engine = engine,
       _typography = typography,
       _cursorColor = cursorColor,
       _selectionColor = selectionColor,
       _showCaret = showCaret,
       _readOnly = readOnly,
       _decorations = decorations,
       _viewportHeight = viewportHeight,
       _scrollOffset = scrollOffset;

  PlainTextEditingController _controller;
  PlainTextLayoutEngine _engine;
  EditorTypography _typography;
  Color _cursorColor;
  Color _selectionColor;
  bool _showCaret;
  bool _readOnly;
  List<TextSpanDecoration> _decorations;
  double _viewportHeight;
  double _scrollOffset;

  set controller(PlainTextEditingController value) {
    if (_controller == value) return;
    _controller = value;
    markNeedsPaint();
  }

  set engine(PlainTextLayoutEngine value) {
    _engine = value;
    markNeedsLayout();
  }

  set typography(EditorTypography value) {
    if (_typography == value) return;
    _typography = value;
    markNeedsLayout();
  }

  set cursorColor(Color value) {
    if (_cursorColor == value) return;
    _cursorColor = value;
    markNeedsPaint();
  }

  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  set showCaret(bool value) {
    if (_showCaret == value) return;
    _showCaret = value;
    markNeedsPaint();
  }

  set readOnly(bool value) => _readOnly = value;

  set decorations(List<TextSpanDecoration> value) {
    _decorations = value;
    markNeedsPaint();
  }

  set viewportHeight(double value) {
    if (_viewportHeight == value) return;
    _viewportHeight = value;
    markNeedsPaint();
  }

  set scrollOffset(double value) {
    if (_scrollOffset == value) return;
    _scrollOffset = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    final maxWidth = constraints.maxWidth;
    _engine.update(
      document: _controller.document,
      typography: _typography,
      viewportWidth: maxWidth,
    );
    // Full document height; the parent ScrollView clips and offsets.
    final minHeight = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
    size = Size(
      maxWidth,
      _engine.totalHeight < minHeight ? minHeight : _engine.totalHeight,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final overscan = _viewportHeight;
    final (first, last) = _engine.visibleParagraphRange(
      scrollOffset: _scrollOffset,
      viewportHeight: _viewportHeight > 0 ? _viewportHeight : size.height,
      overscan: overscan,
    );

    paintTextDecorations(
      canvas: canvas,
      engine: _engine,
      decorations: _decorations,
    );

    final selection = _controller.selection;
    if (!selection.isCollapsed) {
      final boxes = _engine.boxesForSelection(selection);
      final paint = Paint()..color = _selectionColor;
      for (final box in boxes) {
        canvas.drawRect(box, paint);
      }
    }

    if (first <= last) {
      for (var i = first; i <= last; i++) {
        final m = _engine.metrics[i];
        m.painter.paint(canvas, Offset(_engine.contentLeft, m.yOffset));
      }
    }

    final composing = _controller.composing;
    if (composing != null && composing.isValid && !composing.isCollapsed) {
      final boxes = _engine.boxesForRange(composing.start, composing.end);
      final paint = Paint()
        ..color = _cursorColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (final box in boxes) {
        canvas.drawLine(
          Offset(box.left, box.bottom),
          Offset(box.right, box.bottom),
          paint,
        );
      }
    }

    if (_showCaret && !_readOnly && selection.isCollapsed) {
      final caret = _engine.caretRectForOffset(selection.extentOffset);
      if (caret != null) {
        canvas.drawRect(caret, Paint()..color = _cursorColor);
      }
    }

    canvas.restore();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  int offsetForLocalPosition(Offset local) {
    final documentLocal = Offset(local.dx, local.dy + _scrollOffset);
    return _engine.offsetForPosition(documentLocal);
  }

  Offset documentLocalForLocal(Offset local) =>
      Offset(local.dx, local.dy + _scrollOffset);
}

class PlainTextEditorRenderWidget extends LeafRenderObjectWidget {
  const PlainTextEditorRenderWidget({
    super.key,
    required this.controller,
    required this.engine,
    required this.typography,
    required this.cursorColor,
    required this.selectionColor,
    required this.showCaret,
    required this.readOnly,
    required this.decorations,
    required this.viewportHeight,
    required this.scrollOffset,
  });

  final PlainTextEditingController controller;
  final PlainTextLayoutEngine engine;
  final EditorTypography typography;
  final Color cursorColor;
  final Color selectionColor;
  final bool showCaret;
  final bool readOnly;
  final List<TextSpanDecoration> decorations;
  final double viewportHeight;
  final double scrollOffset;

  @override
  PlainTextEditorRenderObject createRenderObject(BuildContext context) {
    return PlainTextEditorRenderObject(
      controller: controller,
      engine: engine,
      typography: typography,
      cursorColor: cursorColor,
      selectionColor: selectionColor,
      showCaret: showCaret,
      readOnly: readOnly,
      decorations: decorations,
      viewportHeight: viewportHeight,
      scrollOffset: scrollOffset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    PlainTextEditorRenderObject renderObject,
  ) {
    renderObject
      ..controller = controller
      ..engine = engine
      ..typography = typography
      ..cursorColor = cursorColor
      ..selectionColor = selectionColor
      ..showCaret = showCaret
      ..readOnly = readOnly
      ..decorations = decorations
      ..viewportHeight = viewportHeight
      ..scrollOffset = scrollOffset;
  }
}
