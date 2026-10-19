import 'package:flutter/widgets.dart';
import 'package:plain_text_editor/input/plain_text_editing_controller.dart';

import '../../../../domain/models/plain_text_format_option.dart';
import '../../../../domain/use_cases/insert_timestamp_text.dart';
import '../../../../domain/use_cases/plain_text_format.dart';
import '../plain_text/zephyr_plain_text_editor.dart';

/// Actions and focus state the IME quick toolbar needs from [WorkspaceEditor].
class WorkspaceEditorBridge extends ChangeNotifier {
  bool _bodyFocused = false;
  bool _canUndo = false;
  bool _suppressBodyIme = false;
  int _firstLineIndent = 2;
  PlainTextEditingController? _controller;
  ZephyrPlainTextEditorState? _editor;
  FocusNode? _focusNode;
  void Function(String text)? _insertPhrase;
  VoidCallback? onDismissToolsPanel;

  bool get bodyFocused => _bodyFocused;
  bool get canUndo => _canUndo;

  /// When true, body taps/scroll keep focus but must not re-show the soft keyboard
  /// (tools panel open — dismiss only on focus loss or tools toggle).
  bool get suppressBodyIme => _suppressBodyIme;

  /// Live editor body; null until [WorkspaceEditor] binds.
  PlainTextEditingController? get controller => _controller;
  FocusNode? get focusNode => _focusNode;

  void bind({
    required PlainTextEditingController controller,
    required ZephyrPlainTextEditorState? editor,
    required FocusNode focusNode,
    required bool bodyFocused,
    required int firstLineIndent,
    void Function(String text)? insertPhrase,
  }) {
    final canUndo = controller.canUndo;
    final changed = !identical(_controller, controller) ||
        !identical(_focusNode, focusNode) ||
        _bodyFocused != bodyFocused ||
        _canUndo != canUndo;
    _controller = controller;
    _editor = editor;
    _focusNode = focusNode;
    _firstLineIndent = firstLineIndent;
    _insertPhrase = insertPhrase;
    _bodyFocused = bodyFocused;
    _canUndo = canUndo;
    if (changed) {
      // [bind] often runs from editor init/sync during build; defer notify.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void notifyCanUndo() {
    final next = _controller?.canUndo ?? false;
    if (_canUndo == next) return;
    _canUndo = next;
    notifyListeners();
  }

  void setBodyFocused(bool focused) {
    if (_bodyFocused == focused) return;
    _bodyFocused = focused;
    notifyListeners();
  }

  void setSuppressBodyIme(bool suppress) {
    if (_suppressBodyIme == suppress) return;
    _suppressBodyIme = suppress;
    notifyListeners();
  }

  void hideIme() => _editor?.hideIme();

  void showIme() => _editor?.showIme();

  /// Chapter title or other chrome took focus — end the tools-panel session.
  void requestDismissToolsPanelForChromeFocus() {
    setSuppressBodyIme(false);
    onDismissToolsPanel?.call();
  }

  /// Taps on the tools panel are outside the editable but should not end the
  /// editing session — keep body primary focus without reopening the IME.
  void retainBodyFocusForToolsOverlay() {
    if (!_suppressBodyIme) return;
    final focus = _focusNode;
    if (focus != null && !focus.hasPrimaryFocus) {
      focus.requestFocus();
    }
    if (!_bodyFocused) {
      _bodyFocused = true;
      notifyListeners();
    }
  }

  /// Keep / restore body focus and show the soft keyboard (caret unchanged).
  void focusBodyAndShowIme() {
    setSuppressBodyIme(false);
    final focus = _focusNode;
    if (focus != null && !focus.hasPrimaryFocus) {
      focus.requestFocus();
    }
    _editor?.showIme();
  }

  void undo() {
    final controller = _controller;
    if (controller == null || !controller.canUndo) return;
    controller.undo();
    notifyCanUndo();
  }

  Future<void> paste() async {
    await _editor?.paste();
    notifyCanUndo();
  }

  void insertIndent() {
    _controller?.insertTabIndent();
    notifyCanUndo();
  }

  void applyFormat() {
    applyFormatOptions(PlainTextFormatSelection.defaults.selected);
  }

  void applyFormatOptions(Set<PlainTextFormatOption> options) {
    final controller = _controller;
    if (controller == null || options.isEmpty) return;
    final next = applyPlainTextFormat(
      controller.text,
      options: options,
      firstLineIndent: _firstLineIndent,
    );
    if (next == controller.text) return;
    controller.setText(next, selection: controller.selection, recordUndo: true);
    notifyCanUndo();
  }

  void applyFormatOption(PlainTextFormatOption option) {
    applyFormatOptions({option});
  }

  void insertPhrase(String text) {
    if (text.isEmpty) return;
    final custom = _insertPhrase;
    if (custom != null) {
      custom(text);
    } else {
      _controller?.insertText(text, coalesce: false);
    }
    notifyCanUndo();
  }

  void insertTimestamp({String? localeName}) {
    insertPhrase(insertTimestampText(localeName: localeName));
  }
}
