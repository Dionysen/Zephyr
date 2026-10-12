import 'package:flutter/services.dart';

import '../text/paired_punctuation.dart';
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
  int? _viewId;
  bool _imeDirty = true;
  /// Mirrors [EditableText]: only [setEditingState] when local ≠ remote.
  /// Echoing every IME compose update breaks Chinese IMEs on Windows.
  TextEditingValue? _lastKnownRemoteValue;
  _PairCaretLock? _pairCaretLock;
  /// Last size/transform pushed to the platform (avoids redundant channel spam).
  Size? _lastEditableSize;
  Matrix4? _lastEditableTransform;

  bool get attached => _connection?.attached ?? false;

  /// Opens (or re-shows) the platform text client.
  ///
  /// [viewId] is required on recent Flutter Windows/macOS embeds; without it
  /// `TextInput.setClient` fails and keystrokes never reach the editor.
  void attach({int? viewId}) {
    // Keep an existing connection; the soft keyboard can be dismissed while
    // focus remains, so every attach must call [show] again.
    final viewChanged = viewId != null && viewId != _viewId;
    if (!attached || viewChanged) {
      if (attached) {
        _connection?.close();
        _connection = null;
      }
      _viewId = viewId;
      _lastKnownRemoteValue = null;
      _connection = TextInput.attach(
        this,
        TextInputConfiguration(
          viewId: viewId,
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
    _viewId = null;
    _lastKnownRemoteValue = null;
    _lastEditableSize = null;
    _lastEditableTransform = null;
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
    syncImeGeometry();
  }

  void markImeDirty() => _imeDirty = true;

  void syncImeIfNeeded() {
    if (!_imeDirty || !attached) return;
    final local = controller.editingValue;
    // Same guard as EditableText._updateRemoteEditingValueIfNeeded.
    if (local != _lastKnownRemoteValue) {
      _connection!.setEditingState(local);
      _lastKnownRemoteValue = local;
    }
    _imeDirty = false;
    // Editing-state equality must not skip geometry: Chinese IMEs place the
    // candidate window from caret/composing rects, which move on scroll.
    syncImeGeometry();
  }

  void _acknowledgeRemoteValue(TextEditingValue value) {
    _lastKnownRemoteValue = value;
    _imeDirty = false;
  }

  /// Push editable size/transform in the same local space as caret rects.
  ///
  /// Prefer the document body [RenderBox] (not the outer scroll viewport):
  /// [PlainTextLayoutEngine.caretRectForOffset] is document-local, and the
  /// body's transform already includes scroll + header translation.
  void updateSizeAndTransform(Size size, Matrix4 transform) {
    if (!attached) return;
    if (_lastEditableSize == size &&
        _lastEditableTransform != null &&
        _matrixAlmostEqual(_lastEditableTransform!, transform)) {
      return;
    }
    _lastEditableSize = size;
    _lastEditableTransform = Matrix4.copy(transform);
    _connection!.setEditableSizeAndTransform(size, transform);
  }

  /// Report caret + composing rects so the platform IME candidate window
  /// tracks the insertion point (required for Chinese/Japanese IMEs).
  void syncImeGeometry() {
    if (!attached) return;
    final local = controller.editingValue;
    final selection = local.selection;
    if (!selection.isValid) return;

    // Match EditableText: use selection.start so directional selections still
    // anchor the candidate menu at the next insertion point.
    final caretOffset = selection.start;
    final caret = engine.caretRectForOffset(caretOffset);
    if (caret != null) {
      _connection!.setCaretRect(caret);
    }

    final composing = local.composing;
    Rect? composingRect;
    if (composing.isValid && !composing.isCollapsed) {
      final boxes = engine.boxesForRange(composing.start, composing.end);
      if (boxes.isNotEmpty) {
        composingRect = boxes.reduce((a, b) => a.expandToInclude(b));
      }
    }
    // Fallback to caret (EditableText does the same before marked text exists).
    composingRect ??= caret ?? engine.caretRectForOffset(
          composing.isValid ? composing.start : caretOffset,
        );
    if (composingRect != null) {
      _connection!.setComposingRect(composingRect);
    }
  }

  static bool _matrixAlmostEqual(Matrix4 a, Matrix4 b) {
    final aa = a.storage;
    final bb = b.storage;
    for (var i = 0; i < 16; i++) {
      if ((aa[i] - bb[i]).abs() > 0.01) return false;
    }
    return true;
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
      _acknowledgeRemoteValue(controller.editingValue);
      return;
    }
    if (_rejectImeSelectionEcho(value)) return;

    final isNewline =
        value.text.length == controller.text.length + 1 &&
        value.selection.isCollapsed &&
        value.selection.extentOffset > 0 &&
        value.text[value.selection.extentOffset - 1] == '\n';
    var locallyAltered = false;
    if (isNewline) {
      if (consumeNewline?.call() == true) {
        // Keep editing state in sync without inserting a break.
        markImeDirty();
        syncImeIfNeeded();
        onRemoteEdit();
        return;
      }
      _pairCaretLock = null;
      controller.insertNewlineWithIndent();
      locallyAltered = true;
    } else if (_isComposing(value)) {
      // Never rewrite composing updates (Chinese/Japanese IME).
      controller.applyEditingValue(value, coalesce: true);
    } else {
      final before = controller.text;
      final next = _expandPairedOpenerValue(before, value);
      locallyAltered = next.text != value.text || next.selection != value.selection;
      controller.applyEditingValue(next, coalesce: false);
    }
    _finishRemoteEdit(locallyAltered: locallyAltered);
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    var value = controller.editingValue;
    var locallyAltered = false;
    for (final delta in textEditingDeltas) {
      if (delta is TextEditingDeltaInsertion && delta.textInserted == '\n') {
        // Do not apply delta.selection: it is post-insert against IME-local
        // text and can clamp to the document end before we insert.
        if (consumeNewline?.call() == true) {
          value = controller.editingValue;
          locallyAltered = true;
          continue;
        }
        _pairCaretLock = null;
        controller.insertNewlineWithIndent();
        value = controller.editingValue;
        locallyAltered = true;
        continue;
      }

      // During IME composing, apply deltas verbatim — pair rewrite / caret
      // pinning corrupts the platform compose session (caret → doc start).
      if (_deltaInvolvesComposing(delta) || _isComposing(value)) {
        value = delta.apply(value);
        controller.applyEditingValue(value, coalesce: true);
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
          composing: value.composing,
        );
        controller.applyEditingValue(value, coalesce: false);
        value = controller.editingValue;
        locallyAltered = true;
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
        locallyAltered = true;
        continue;
      }
      final beforeApply = value.text;
      value = delta.apply(value);
      final pinned = _pinCaretBetweenPair(beforeApply, value);
      if (pinned != value) locallyAltered = true;
      value = pinned;
      controller.applyEditingValue(value);
      value = controller.editingValue;
    }
    _finishRemoteEdit(locallyAltered: locallyAltered);
  }

  bool _isComposing(TextEditingValue value) =>
      value.composing.isValid && !value.composing.isCollapsed;

  bool _deltaInvolvesComposing(TextEditingDelta delta) =>
      delta.composing.isValid && !delta.composing.isCollapsed;

  /// After an IME-driven edit: acknowledge remote state, or push only when we
  /// changed text/selection beyond what the platform sent.
  void _finishRemoteEdit({required bool locallyAltered}) {
    if (locallyAltered) {
      markImeDirty();
      syncImeIfNeeded();
    } else {
      _acknowledgeRemoteValue(controller.editingValue);
    }
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
    _viewId = null;
    _lastKnownRemoteValue = null;
    _lastEditableSize = null;
    _lastEditableTransform = null;
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
