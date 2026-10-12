import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/input/plain_text_editing_controller.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/editor_typography.dart';
import 'package:zephyr/ui/features/editor/plain_text/zephyr_plain_text_editor.dart';

void main() {
  const typography = EditorTypography(
    color: Color(0xFF000000),
    fontSize: 16,
    fontFamily: 'Roboto',
    lineHeight: 1.5,
    paragraphSpacing: 0,
    marginLeft: 16,
    marginRight: 16,
    firstLineIndent: 0,
    paddingTop: 0,
    paddingBottom: 0,
  );

  testWidgets('focused editor attaches TextInput with viewId and accepts edits', (
    tester,
  ) async {
    final controller = PlainTextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrPlainTextEditor(
            controller: controller,
            typography: typography,
            cursorColor: Colors.black,
            selectionColor: Colors.blue.withValues(alpha: 0.3),
            onTextChanged: (_) {},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ZephyrPlainTextEditor));
    await tester.pump();
    // Focus settles on a microtask after requestFocus.
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, isTrue);
    // Desktop embeds require viewId on setClient (mirrors EditableText).
    expect(
      tester.testTextInput.setClientArgs?['viewId'],
      isNotNull,
      reason: 'TextInputConfiguration.viewId must be set for Windows/macOS',
    );

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'hello',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pump();

    expect(controller.text, 'hello');
  });

  testWidgets('composing updates are not echoed via setEditingState', (
    tester,
  ) async {
    final controller = PlainTextEditingController(text: 'hello');
    controller.setSelection(const TextSelection.collapsed(offset: 5));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrPlainTextEditor(
            controller: controller,
            typography: typography,
            cursorColor: Colors.black,
            selectionColor: Colors.blue.withValues(alpha: 0.3),
            onTextChanged: (_) {},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ZephyrPlainTextEditor));
    await tester.pump();
    await tester.pump();

    // Clear the attach-time setEditingState from the channel log.
    tester.testTextInput.log.clear();

    // Simulate Chinese IME composing "n" then "ni" at caret.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'hellon',
        selection: TextSelection.collapsed(offset: 6),
        composing: TextRange(start: 5, end: 6),
      ),
    );
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'helloni',
        selection: TextSelection.collapsed(offset: 7),
        composing: TextRange(start: 5, end: 7),
      ),
    );
    await tester.pump();

    expect(controller.text, 'helloni');
    expect(controller.composing, const TextRange(start: 5, end: 7));
    // Must not push setEditingState back during unchanged compose applies —
    // that resets Windows IMEs (caret jumps to doc start).
    final setStateCalls = tester.testTextInput.log
        .where((call) => call.method == 'TextInput.setEditingState')
        .length;
    expect(setStateCalls, 0);
  });
}
