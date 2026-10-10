import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/use_cases/paragraph_indentation.dart';
import '../../../../../domain/use_cases/text_word_boundaries.dart';
import '../document/plain_text_document.dart';
import '../document/plain_text_selection.dart';

/// Holds text, selection, composing, and a simple undo stack.
class PlainTextEditingController extends ChangeNotifier {
  PlainTextEditingController({
    String text = '',
    TextSelection selection = const TextSelection.collapsed(offset: 0),
  }) : _document = PlainTextDocument(text),
       _selection = selection.clampedTo(text.length);

  PlainTextDocument _document;
  TextSelection _selection;
  TextRange? _composing = TextRange.empty;
  int _firstLineIndent = 0;

  final List<_Snapshot> _undo = [];
  final List<_Snapshot> _redo = [];
  DateTime? _lastCoalesceAt;
  static const _coalesceWindow = Duration(milliseconds: 800);
  static const _maxUndo = 100;

  PlainTextDocument get document => _document;
  String get text => _document.text;
  TextSelection get selection => _selection;
  TextRange? get composing => _composing;
  int get firstLineIndent => _firstLineIndent;

  set firstLineIndent(int value) {
    if (_firstLineIndent == value) return;
    _firstLineIndent = value;
  }

  void setText(String text, {TextSelection? selection, bool recordUndo = false}) {
    if (recordUndo) _pushUndo();
    _document = PlainTextDocument(text);
    _selection = (selection ?? TextSelection.collapsed(offset: text.length))
        .clampedTo(text.length);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  void setSelection(TextSelection selection) {
    final next = selection.clampedTo(_document.length);
    if (next == _selection) return;
    _selection = next;
    notifyListeners();
  }

  void setComposing(TextRange? range) {
    _composing = range;
    notifyListeners();
  }

  void replaceSelection(String replacement, {bool coalesce = false}) {
    _pushUndo(coalesce: coalesce);
    final start = _selection.start;
    final end = _selection.end;
    _document = _document.replaceRange(start, end, replacement);
    final caret = start + replacement.length;
    _selection = TextSelection.collapsed(offset: caret);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  void insertText(String value, {bool coalesce = true}) {
    replaceSelection(value, coalesce: coalesce);
  }

  void deleteBackward() {
    if (!_selection.isCollapsed) {
      replaceSelection('');
      return;
    }
    if (_selection.extentOffset == 0) return;
    final end = _selection.extentOffset;
    final start = end - 1;
    // Delete the prior code unit without expanding selection first — that
    // would snapshot a range and make undo re-select the restored character.
    _pushUndo(coalesce: false);
    _document = _document.replaceRange(start, end, '');
    _selection = TextSelection.collapsed(offset: start);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  void deleteForward() {
    if (!_selection.isCollapsed) {
      replaceSelection('');
      return;
    }
    if (_selection.extentOffset >= _document.length) return;
    final start = _selection.extentOffset;
    final end = start + 1;
    _pushUndo(coalesce: false);
    _document = _document.replaceRange(start, end, '');
    _selection = TextSelection.collapsed(offset: start);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  /// Inserts a newline and inherits leading ideographic indent from the
  /// current paragraph.
  void insertNewlineWithIndent() {
    final offset = _selection.extentOffset;
    final paraIndex = _document.paragraphIndexForOffset(offset);
    final paras = _document.paragraphs;
    final current = paras[paraIndex];
    final starts = _document.paragraphStarts();
    final local = offset - starts[paraIndex];
    final linePrefix = current.substring(0, local.clamp(0, current.length));
    // Indent is taken from the full paragraph's leading spaces (writing style).
    final indent = leadingIdeographicIndentCount(current);
    final insertion = '\n${ideographicIndent(indent)}';
    // If caret is mid-paragraph after some text that wasn't indented on this
    // visual line, still inherit paragraph leading indent.
    if (indent == 0 && linePrefix.isNotEmpty) {
      // keep zero
    }
    replaceSelection(insertion, coalesce: false);
  }

  void insertTabIndent() {
    if (_firstLineIndent <= 0) return;
    insertText(ideographicIndent(_firstLineIndent), coalesce: false);
  }

  /// Removes up to [firstLineIndent] leading ideographic spaces at the caret
  /// line (or the selection start line).
  void outdentTabIndent() {
    if (_firstLineIndent <= 0) return;
    final offset = _selection.start;
    final paraIndex = _document.paragraphIndexForOffset(offset);
    final starts = _document.paragraphStarts();
    final paraStart = starts[paraIndex];
    final para = _document.paragraphs[paraIndex];
    final leading = leadingIdeographicIndentCount(para);
    if (leading <= 0) return;
    final remove = leading < _firstLineIndent ? leading : _firstLineIndent;
    _pushUndo(coalesce: false);
    _document = _document.replaceRange(paraStart, paraStart + remove, '');
    final delta = remove;
    final base = (_selection.baseOffset - delta).clamp(0, _document.length);
    final extent = (_selection.extentOffset - delta).clamp(0, _document.length);
    _selection = TextSelection(baseOffset: base, extentOffset: extent);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  void selectAll() {
    setSelection(
      TextSelection(baseOffset: 0, extentOffset: _document.length),
    );
  }

  int lineStartOffset(int offset) {
    final i = _document.paragraphIndexForOffset(offset);
    return _document.paragraphStarts()[i];
  }

  int lineEndOffset(int offset) {
    final i = _document.paragraphIndexForOffset(offset);
    final starts = _document.paragraphStarts();
    final start = starts[i];
    return start + _document.paragraphs[i].length;
  }

  void moveCaret(int offset, {bool extend = false}) {
    final next = offset.clamp(0, _document.length);
    if (extend) {
      setSelection(
        TextSelection(
          baseOffset: _selection.baseOffset,
          extentOffset: next,
        ),
      );
    } else {
      setSelection(TextSelection.collapsed(offset: next));
    }
  }

  void moveWordLeft({bool extend = false}) {
    moveCaret(wordBoundaryLeft(text, _selection.extentOffset), extend: extend);
  }

  void moveWordRight({bool extend = false}) {
    moveCaret(wordBoundaryRight(text, _selection.extentOffset), extend: extend);
  }

  void moveLineStart({bool extend = false}) {
    moveCaret(lineStartOffset(_selection.extentOffset), extend: extend);
  }

  void moveLineEnd({bool extend = false}) {
    moveCaret(lineEndOffset(_selection.extentOffset), extend: extend);
  }

  void moveDocumentStart({bool extend = false}) {
    moveCaret(0, extend: extend);
  }

  void moveDocumentEnd({bool extend = false}) {
    moveCaret(_document.length, extend: extend);
  }

  void deleteWordBackward() {
    if (!_selection.isCollapsed) {
      replaceSelection('');
      return;
    }
    final end = _selection.extentOffset;
    if (end == 0) return;
    final start = wordBoundaryLeft(text, end);
    if (start >= end) return;
    _pushUndo(coalesce: false);
    _document = _document.replaceRange(start, end, '');
    _selection = TextSelection.collapsed(offset: start);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  void deleteWordForward() {
    if (!_selection.isCollapsed) {
      replaceSelection('');
      return;
    }
    final start = _selection.extentOffset;
    if (start >= _document.length) return;
    final end = wordBoundaryRight(text, start);
    if (end <= start) return;
    _pushUndo(coalesce: false);
    _document = _document.replaceRange(start, end, '');
    _selection = TextSelection.collapsed(offset: start);
    _composing = TextRange.empty;
    _redo.clear();
    notifyListeners();
  }

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_Snapshot(text: text, selection: _selection));
    final snap = _undo.removeLast();
    _restoreSnapshot(snap);
    _lastCoalesceAt = null;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_Snapshot(text: text, selection: _selection));
    final snap = _redo.removeLast();
    _restoreSnapshot(snap);
    notifyListeners();
  }

  /// Restores text with a collapsed caret — never re-selects a prior range.
  void _restoreSnapshot(_Snapshot snap) {
    _document = PlainTextDocument(snap.text);
    final caret = snap.selection.extentOffset.clamp(0, snap.text.length);
    _selection = TextSelection.collapsed(offset: caret);
    _composing = TextRange.empty;
  }

  void _pushUndo({bool coalesce = false}) {
    final now = DateTime.now();
    if (coalesce &&
        _lastCoalesceAt != null &&
        now.difference(_lastCoalesceAt!) < _coalesceWindow &&
        _undo.isNotEmpty) {
      _lastCoalesceAt = now;
      return;
    }
    _undo.add(_Snapshot(text: text, selection: _selection));
    if (_undo.length > _maxUndo) {
      _undo.removeAt(0);
    }
    _lastCoalesceAt = now;
  }

  TextEditingValue get editingValue => TextEditingValue(
    text: text,
    selection: _selection,
    composing: _composing ?? TextRange.empty,
  );

  void applyEditingValue(TextEditingValue value, {bool coalesce = true}) {
    _pushUndo(coalesce: coalesce);
    _document = PlainTextDocument(value.text);
    _selection = value.selection.clampedTo(value.text.length);
    _composing = value.composing;
    _redo.clear();
    notifyListeners();
  }
}

class _Snapshot {
  const _Snapshot({required this.text, required this.selection});
  final String text;
  final TextSelection selection;
}
