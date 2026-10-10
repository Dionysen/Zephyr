import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/plain_text_format.dart';
import 'package:zephyr/ui/features/editor/plain_text/input/plain_text_editing_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('undo restores text from the history stack', () {
    final controller = PlainTextEditingController(text: 'Hello');
    controller.setSelection(const TextSelection.collapsed(offset: 5));
    controller.insertText(' world', coalesce: false);
    expect(controller.text, 'Hello world');
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(controller.text, 'Hello');
  });

  test('indent inserts configured ideographic spaces', () {
    final controller = PlainTextEditingController(text: '');
    controller.firstLineIndent = 2;
    controller.insertTabIndent();
    expect(controller.text, '　　');
  });

  test('phrase insert and format go through undo', () {
    final controller = PlainTextEditingController(text: 'A\n\n\nB');
    controller.setSelection(const TextSelection.collapsed(offset: 6));
    controller.insertText('—署名', coalesce: false);
    expect(controller.text, 'A\n\n\nB—署名');
    final formatted = formatPlainTextDocument('First\n\n\nSecond', 2);
    controller.setText(formatted, recordUndo: true);
    expect(controller.text, '　　First\n\n　　Second');
    controller.undo();
    expect(controller.text, 'A\n\n\nB—署名');
  });

  test('paste replaces the selection', () async {
    final controller = PlainTextEditingController(text: 'abcd');
    controller.setSelection(
      const TextSelection(baseOffset: 1, extentOffset: 3),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': 'XX'};
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    controller.replaceSelection(data?.text ?? '', coalesce: false);
    expect(controller.text, 'aXXd');
  });
}
