import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../layout/plain_text_layout_engine.dart';
import 'plain_text_editing_controller.dart';

/// Bridges [PlainTextEditingController] to the platform IME.
class PlainTextInputClient with TextInputClient, DeltaTextInputClient {
  PlainTextInputClient({
    required this.controller,
    required this.engine,
    required this.onRemoteEdit,
  });

  final PlainTextEditingController controller;
  final PlainTextLayoutEngine engine;
  final VoidCallback onRemoteEdit;

  TextInputConnection? _connection;
  bool _imeDirty = true;

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
    final isNewline =
        value.text.length == controller.text.length + 1 &&
        value.selection.isCollapsed &&
        value.selection.extentOffset > 0 &&
        value.text[value.selection.extentOffset - 1] == '\n';
    if (isNewline) {
      controller.insertNewlineWithIndent();
    } else {
      controller.applyEditingValue(value);
    }
    markImeDirty();
    onRemoteEdit();
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    var value = controller.editingValue;
    for (final delta in textEditingDeltas) {
      if (delta is TextEditingDeltaInsertion && delta.textInserted == '\n') {
        // Do not apply delta.selection: it is post-insert against IME-local
        // text and can clamp to the document end before we insert.
        controller.insertNewlineWithIndent();
        value = controller.editingValue;
        continue;
      }
      value = delta.apply(value);
      controller.applyEditingValue(value);
      value = controller.editingValue;
    }
    markImeDirty();
    onRemoteEdit();
  }

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.newline) {
      controller.insertNewlineWithIndent();
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
