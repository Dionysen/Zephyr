import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/input/plain_text_editing_controller.dart';

void main() {
  test('outdent removes leading ideographic indent', () {
    final controller = PlainTextEditingController(text: '　　Hello');
    controller.firstLineIndent = 2;
    controller.setSelection(const TextSelection.collapsed(offset: 4));
    controller.outdentTabIndent();
    expect(controller.text, 'Hello');
    expect(controller.selection.extentOffset, 2);
  });

  test('moveWordLeft and deleteWordBackward', () {
    final controller = PlainTextEditingController(text: 'one two');
    controller.setSelection(const TextSelection.collapsed(offset: 7));
    controller.moveWordLeft();
    expect(controller.selection.extentOffset, 4);
    controller.deleteWordBackward();
    expect(controller.text, 'two');
  });

  test('document and line navigation', () {
    final controller = PlainTextEditingController(text: 'ab\ncd');
    controller.setSelection(const TextSelection.collapsed(offset: 4));
    controller.moveLineStart();
    expect(controller.selection.extentOffset, 3);
    controller.moveDocumentStart();
    expect(controller.selection.extentOffset, 0);
    controller.moveDocumentEnd(extend: true);
    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 5);
  });
}
