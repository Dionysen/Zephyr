import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../document/plain_text_selection.dart';
import '../input/plain_text_editing_controller.dart';
import '../layout/plain_text_layout_engine.dart';

/// Pointer gestures for caret placement and selection.
class PlainTextGestureHandler {
  PlainTextGestureHandler({
    required this.controller,
    required this.engine,
    required this.onChanged,
    required this.documentToGlobal,
  });

  final PlainTextEditingController controller;
  final PlainTextLayoutEngine engine;
  final VoidCallback onChanged;

  /// Converts a document-local offset to a position usable by [engine].
  final Offset Function(Offset local) documentToGlobal;

  int _tapCount = 0;
  DateTime? _lastTapAt;
  Offset? _lastTapPos;

  void handleTapDown(TapDownDetails details, Offset documentLocal) {
    final now = DateTime.now();
    final pos = details.localPosition;
    if (_lastTapAt != null &&
        now.difference(_lastTapAt!) < const Duration(milliseconds: 350) &&
        _lastTapPos != null &&
        (pos - _lastTapPos!).distance < 24) {
      _tapCount += 1;
    } else {
      _tapCount = 1;
    }
    _lastTapAt = now;
    _lastTapPos = pos;

    final offset = engine.offsetForPosition(documentLocal);
    if (_tapCount == 1) {
      controller.setSelection(TextSelection.collapsed(offset: offset));
    } else if (_tapCount == 2) {
      controller.setSelection(_wordSelectionAt(offset));
    } else {
      controller.setSelection(_paragraphSelectionAt(offset));
      _tapCount = 0;
    }
    onChanged();
  }

  void handleDragUpdate(Offset documentLocal, {required bool selecting}) {
    final offset = engine.offsetForPosition(documentLocal);
    controller.setSelection(
      controller.selection.withExtentAt(offset, selecting: selecting),
    );
    onChanged();
  }

  void handleDragStart(Offset documentLocal) {
    final offset = engine.offsetForPosition(documentLocal);
    controller.setSelection(TextSelection.collapsed(offset: offset));
    onChanged();
  }

  TextSelection _wordSelectionAt(int offset) {
    final text = controller.text;
    if (text.isEmpty) {
      return const TextSelection.collapsed(offset: 0);
    }
    final o = offset.clamp(0, text.length);
    var start = o;
    var end = o;
    bool isWord(int code) {
      final c = String.fromCharCode(code);
      return RegExp(r'[\w\u4e00-\u9fff]').hasMatch(c);
    }

    while (start > 0 && isWord(text.codeUnitAt(start - 1))) {
      start--;
    }
    while (end < text.length && isWord(text.codeUnitAt(end))) {
      end++;
    }
    if (start == end) {
      return TextSelection.collapsed(offset: o);
    }
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  TextSelection _paragraphSelectionAt(int offset) {
    final doc = controller.document;
    final index = doc.paragraphIndexForOffset(offset);
    final starts = doc.paragraphStarts();
    final start = starts[index];
    final end = start + doc.paragraphs[index].length;
    return TextSelection(baseOffset: start, extentOffset: end);
  }
}
