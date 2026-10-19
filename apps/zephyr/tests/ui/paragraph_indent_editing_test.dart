import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/input/plain_text_editing_controller.dart';

void main() {
  test('Enter inherits leading ideographic indent from the previous paragraph', () {
    final controller = PlainTextEditingController(text: '　　Hello');
    controller.setSelection(
      TextSelection.collapsed(offset: controller.text.length),
    );
    controller.insertNewlineWithIndent();

    expect(controller.text, '　　Hello\n　　');
    expect(controller.selection.extentOffset, controller.text.length);
  });

  test('Enter mid-document keeps the caret on the new paragraph', () {
    final controller = PlainTextEditingController(text: '　　Hello\n　　World');
    // Caret at end of first paragraph (after "Hello").
    controller.setSelection(const TextSelection.collapsed(offset: 7));
    controller.insertNewlineWithIndent();

    expect(controller.text, '　　Hello\n　　\n　　World');
    expect(controller.selection.extentOffset, 10); // after inherited indent
  });

  test('Enter does not add indent when the previous paragraph has none', () {
    final controller = PlainTextEditingController(text: 'Hello');
    controller.setSelection(
      TextSelection.collapsed(offset: controller.text.length),
    );
    controller.insertNewlineWithIndent();

    expect(controller.text, 'Hello\n');
  });

  test('splitting mid-paragraph prefixes the carried text with inherited indent', () {
    final controller = PlainTextEditingController(text: '　　HelloWorld');
    controller.setSelection(const TextSelection.collapsed(offset: 7));
    controller.insertNewlineWithIndent();

    expect(controller.text, '　　Hello\n　　World');
  });

  test('Tab inserts configured ideographic indent', () {
    final controller = PlainTextEditingController(text: '');
    controller.firstLineIndent = 2;
    controller.insertTabIndent();
    expect(controller.text, '　　');
  });
}
