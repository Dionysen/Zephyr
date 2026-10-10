import 'package:flutter/foundation.dart';

import '../../../../domain/use_cases/plain_text_format.dart';
import '../plain_text/input/plain_text_editing_controller.dart';
import '../plain_text/zephyr_plain_text_editor.dart';

/// Actions and focus state the IME quick toolbar needs from [WorkspaceEditor].
class WorkspaceEditorBridge extends ChangeNotifier {
  bool _bodyFocused = false;
  bool _canUndo = false;
  int _firstLineIndent = 2;
  PlainTextEditingController? _controller;
  ZephyrPlainTextEditorState? _editor;

  bool get bodyFocused => _bodyFocused;
  bool get canUndo => _canUndo;

  void bind({
    required PlainTextEditingController controller,
    required ZephyrPlainTextEditorState? editor,
    required bool bodyFocused,
    required int firstLineIndent,
  }) {
    _controller = controller;
    _editor = editor;
    _firstLineIndent = firstLineIndent;
    final canUndo = controller.canUndo;
    final changed =
        _bodyFocused != bodyFocused || _canUndo != canUndo;
    _bodyFocused = bodyFocused;
    _canUndo = canUndo;
    if (changed) notifyListeners();
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

  void hideIme() => _editor?.hideIme();

  void showIme() => _editor?.showIme();

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
    final controller = _controller;
    if (controller == null) return;
    final next = formatPlainTextDocument(controller.text, _firstLineIndent);
    if (next == controller.text) return;
    controller.setText(next, selection: controller.selection, recordUndo: true);
    notifyCanUndo();
  }

  void insertPhrase(String text) {
    if (text.isEmpty) return;
    _controller?.insertText(text, coalesce: false);
    notifyCanUndo();
  }
}
