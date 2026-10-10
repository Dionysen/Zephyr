import 'package:flutter/services.dart';

import '../../../../../domain/use_cases/paired_punctuation.dart';
import '../layout/plain_text_layout_engine.dart';
import 'plain_text_editing_controller.dart';

/// Brief lock so the IME cannot yank the caret onto the pair glyphs right
/// after we expand/pin a wrap (common with Chinese `“”` commit).
class _PairCaretLock {
  _PairCaretLock({
    required this.openIndex,
    required this.caret,
    required this.highlightEnd,
    required this.untilMs,
  });

  final int openIndex;
  final int caret;
  final int highlightEnd;
  final int untilMs;

  bool get expired =>
      DateTime.now().millisecondsSinceEpoch > untilMs;

  bool coversOffset(int offset) =>
      offset >= openIndex && offset <= highlightEnd;
}

/// Bridges [PlainTextEditingController] to the platform IME.
class PlainTextInputClient with TextInputClient, DeltaTextInputClient {
  PlainTextInputClient({
    required this.controller,
    required this.engine,
    required this.onRemoteEdit,
    this.consumeNewline,
  });

  final PlainTextEditingController controller;
  final PlainTextLayoutEngine engine;
  final VoidCallback onRemoteEdit;

  /// When true, a newline from the IME is swallowed (e.g. exit pair wrap).
  bool Function()? consumeNewline;

  TextInputConnection? _connection;
  bool _imeDirty = true;
  _PairCaretLock? _pairCaretLock;

  bool get attached => _connection?.attached ?? false;

  void attach() {
    // Keep an existing connection; the soft keyboard can be dismissed while
    // focus remains, so every attach must call [show] again.
    if (!attached) {
      _connection = TextInput.attach(
        this,
        const TextInputConfiguration(
          inputType: TextInputType.multiline,
          inputAction: TextInputAction.newline,
          keyboardAppearance: Brightness.light,
          enableDeltaModel: true,
        ),
      );
    }
    showIme();
  }

  void detach() {
    _connection?.close();
    _connection = null;
  }

  /// Hides the soft keyboard without closing the text-input connection.
  void hideIme() {
    if (!attached) return;
    // Platform channel hide keeps the connection attached (unlike [close]).
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  /// Shows the soft keyboard for an already-attached connection.
  void showIme() {
    if (!attached) return;
    _connection!.show();
    markImeDirty();
    syncImeIfNeeded();
  }

  void markImeDirty() => _imeDirty = true;

  void syncImeIfNeeded() {
    if (!_imeDirty || !attached) return;
    _connection!.setEditingState(controller.editingValue);
    final caret = engine.caretRectForOffset(controller.selection.extentOffset);
    if (caret != null) {
      _connection!.setCaretRect(caret);
    }
    _imeDirty = false;
  }

  void updateSizeAndTransform(Size size, Matrix4 transform) {
    if (!attached) return;
    _connection!.setEditableSizeAndTransform(size, transform);
  }

  /// Hold the caret between a just-inserted pair so the IME cannot yank it
  /// onto the opener/closer glyphs for a short window.
  void lockPairCaret({
    required int openIndex,
    required int caret,
    required int highlightEnd,
  }) {
    _pairCaretLock = _PairCaretLock(
      openIndex: openIndex,
      caret: caret,
      highlightEnd: highlightEnd,
      untilMs: DateTime.now().millisecondsSinceEpoch + 600,
    );
  }

  _PairCaretLock? get _activePairLock {
    final lock = _pairCaretLock;
    if (lock == null) return null;
    if (lock.expired) {
      _pairCaretLock = null;
      return null;
    }
    return lock;
  }

  /// Reject IME selection echoes that yank the caret onto the pair glyphs.
  bool _rejectImeSelectionEcho(TextEditingValue value) {
    final lock = _activePairLock;
    if (lock == null) return false;
    if (value.text != controller.text) return false;
    if (!value.selection.isCollapsed) return false;
    final offset = value.selection.extentOffset;
    if (offset == lock.caret) return false;
    if (!lock.coversOffset(offset)) {
      // User moved outside the pair — release the lock.
      _pairCaretLock = null;
      return false;
    }
    markImeDirty();
    syncImeIfNeeded();
    return true;
  }

  @override
  TextEditingValue? get currentTextEditingValue => controller.editingValue;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    // Non-delta fallback.
    if (value.text == controller.text &&
        value.selection == controller.selection &&
        value.composing == controller.composing) {
      return;
    }
    if (_rejectImeSelectionEcho(value)) return;

    final isNewline =
        value.text.length == controller.text.length + 1 &&
        value.selection.isCollapsed &&
        value.selection.extentOffset > 0 &&
        value.text[value.selection.extentOffset - 1] == '\n';
    if (isNewline) {
      if (consumeNewline?.call() == true) {
        // Keep editing state in sync without inserting a break.
        markImeDirty();
        syncImeIfNeeded();
        return;
      }
      _pairCaretLock = null;
      controller.insertNewlineWithIndent();
    } else {
      controller.applyEditingValue(
        _expandPairedOpenerValue(controller.text, value),
        coalesce: false,
      );
    }
    markImeDirty();
    syncImeIfNeeded();
    onRemoteEdit();
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    var value = controller.editingValue;
    for (final delta in textEditingDeltas) {
      if (delta is TextEditingDeltaInsertion && delta.textInserted == '\n') {
        // Do not apply delta.selection: it is post-insert against IME-local
        // text and can clamp to the document end before we insert.
        if (consumeNewline?.call() == true) {
          value = controller.editingValue;
          continue;
        }
        _pairCaretLock = null;
        controller.insertNewlineWithIndent();
        value = controller.editingValue;
        continue;
      }

      // IME often commits `“` then `”` after we already expanded — skip the
      // duplicate closer and keep the caret between.
      if (delta is TextEditingDeltaInsertion &&
          isRedundantPairedCloserInsert(
            text: value.text,
            offset: delta.insertionOffset,
            closer: delta.textInserted,
          )) {
        final caret = delta.insertionOffset;
        // If the closer is being appended after the pair, pin between.
        final pin = _caretBetweenExistingPair(value.text, caret) ?? caret;
        value = TextEditingValue(
          text: value.text,
          selection: TextSelection.collapsed(offset: pin),
        );
        controller.applyEditingValue(value, coalesce: false);
        value = controller.editingValue;
        continue;
      }

      final pairInsert = _pairInsertFromDelta(delta);
      if (pairInsert != null) {
        // Always insert the full pair and pin the caret between glyphs.
        // Ignore the platform selection (often lands before/after the pair).
        final text = value.text;
        final nextText = text.replaceRange(
          pairInsert.start,
          pairInsert.end,
          pairInsert.pair.text,
        );
        final openIndex = pairInsert.start;
        final caret = openIndex + pairInsert.pair.open.length;
        final highlightEnd = openIndex + pairInsert.pair.text.length;
        value = TextEditingValue(
          text: nextText,
          selection: TextSelection.collapsed(offset: caret),
        );
        controller.applyEditingValue(value, coalesce: false);
        lockPairCaret(
          openIndex: openIndex,
          caret: caret,
          highlightEnd: highlightEnd,
        );
        value = controller.editingValue;
        continue;
      }
      final beforeApply = value.text;
      value = delta.apply(value);
      // Platform may leave the caret after a full pair; pin between glyphs.
      value = _pinCaretBetweenPair(beforeApply, value);
      controller.applyEditingValue(value);
      value = controller.editingValue;
    }
    markImeDirty();
    syncImeIfNeeded();
    onRemoteEdit();
  }

  /// Expand a lone opener to a full pair, and always pin caret between.
  /// Full pair payloads (`“”`) are left as-is with the caret between.
  TextEditingValue _expandPairedOpenerValue(
    String before,
    TextEditingValue next,
  ) {
    final typed = detectTypedPairedPunctuation(before: before, after: next.text);
    if (typed == null) {
      return _pinCaretBetweenPair(before, next);
    }
    final pair = typed.pair;
    final openIndex = typed.openIndex;
    final openEnd = openIndex + pair.open.length;
    final caret = TextSelection.collapsed(offset: openEnd);
    if (typed.needsCloser) {
      final text = next.text;
      final expanded =
          text.substring(0, openEnd) + pair.close + text.substring(openEnd);
      lockPairCaret(
        openIndex: openIndex,
        caret: openEnd,
        highlightEnd: openEnd + pair.close.length,
      );
      return TextEditingValue(text: expanded, selection: caret);
    }
    // Full pair already present — still force caret between the glyphs.
    lockPairCaret(
      openIndex: openIndex,
      caret: openEnd,
      highlightEnd: openIndex + pair.text.length,
    );
    return TextEditingValue(text: next.text, selection: caret);
  }

  /// When a replacement/composing commit left a full pair with the caret
  /// after the closer (or on either glyph), move it into the interior.
  TextEditingValue _pinCaretBetweenPair(String before, TextEditingValue next) {
    final edit = findTextEditRange(before, next.text);
    if (edit == null) return next;
    final inserted = edit.insertedIn(next.text);
    final pair = resolvePairedPunctuationInsert(inserted);
    if (pair == null || inserted != pair.text) return next;
    final openEnd = edit.afterStart + pair.open.length;
    lockPairCaret(
      openIndex: edit.afterStart,
      caret: openEnd,
      highlightEnd: edit.afterStart + pair.text.length,
    );
    if (next.selection.isCollapsed && next.selection.extentOffset == openEnd) {
      return next;
    }
    return TextEditingValue(
      text: next.text,
      selection: TextSelection.collapsed(offset: openEnd),
      composing: next.composing,
    );
  }

  /// If [offset] sits on/after an empty pair, return the interior caret.
  int? _caretBetweenExistingPair(String text, int offset) {
    for (final entry in pairedPunctuationClosers.entries) {
      final open = entry.key;
      final close = entry.value;
      final pairLen = open.length + close.length;
      // Appended after `“”` → pin between.
      if (offset >= pairLen) {
        final start = offset - pairLen;
        if (text.substring(start, offset) == '$open$close') {
          return start + open.length;
        }
      }
      // Inserting into the interior of an existing empty pair.
      if (offset >= open.length &&
          offset + close.length <= text.length &&
          text.substring(offset - open.length, offset) == open &&
          text.substring(offset, offset + close.length) == close) {
        return offset;
      }
    }
    return null;
  }

  ({PairedPunctuationInsert pair, int start, int end})? _pairInsertFromDelta(
    TextEditingDelta delta,
  ) {
    if (delta is TextEditingDeltaInsertion) {
      final pair = resolvePairedPunctuationInsert(delta.textInserted);
      if (pair == null) return null;
      if (delta.textInserted != pair.open &&
          delta.textInserted != pair.text) {
        return null;
      }
      return (
        pair: pair,
        start: delta.insertionOffset,
        end: delta.insertionOffset,
      );
    }
    if (delta is TextEditingDeltaReplacement) {
      final pair = resolvePairedPunctuationInsert(delta.replacementText);
      if (pair == null) return null;
      if (delta.replacementText != pair.open &&
          delta.replacementText != pair.text) {
        return null;
      }
      return (
        pair: pair,
        start: delta.replacedRange.start,
        end: delta.replacedRange.end,
      );
    }
    return null;
  }

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) {
      if (consumeNewline?.call() != true) {
        _pairCaretLock = null;
        controller.insertNewlineWithIndent();
      }
      markImeDirty();
      onRemoteEdit();
      syncImeIfNeeded();
    }
  }

  @override
  void performSelector(String selectorName) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {
    _connection = null;
  }

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}
}
