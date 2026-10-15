import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  testWidgets(
    'focused editor attaches TextInput with viewId and accepts edits',
    (tester) async {
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
              onShareSelectedText: (_, _) async {},
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
    },
  );

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
            onShareSelectedText: (_, _) async {},
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

  testWidgets(
    'mobile selection shows horizontal actions and hides Select all after selecting all',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final controller = PlainTextEditingController(text: 'Hello world');
      addTearDown(controller.dispose);
      String? sharedText;
      Rect? sharedOrigin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZephyrPlainTextEditor(
              controller: controller,
              typography: typography,
              cursorColor: Colors.black,
              selectionColor: Colors.blue,
              onTextChanged: (_) {},
              onSelectionChanged: (_) {},
              onShareSelectedText: (text, origin) async {
                sharedText = text;
                sharedOrigin = origin;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ZephyrPlainTextEditor));
      await tester.pump();
      controller.setSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      await tester.pump();

      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Select all'), findsOneWidget);

      await tester.tap(find.text('Share'));
      await tester.pump();
      expect(sharedText, 'Hello');
      expect(sharedOrigin, isNotNull);
      expect(sharedOrigin!.width, greaterThan(0));

      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(controller.selection.start, 0);
      expect(controller.selection.end, controller.text.length);
      expect(find.text('Select all'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);

      controller.setSelection(const TextSelection.collapsed(offset: 2));
      await tester.pump();
      expect(find.text('Copy'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('mobile Cut, Copy and Paste use selected text', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = PlainTextEditingController(text: 'Hello world');
    addTearDown(controller.dispose);
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText = (call.arguments as Map)['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': clipboardText};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrPlainTextEditor(
            controller: controller,
            typography: typography,
            cursorColor: Colors.black,
            selectionColor: Colors.blue,
            onTextChanged: (_) {},
            onSelectionChanged: (_) {},
            onShareSelectedText: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ZephyrPlainTextEditor));
    await tester.pump();
    controller.setSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    await tester.pump();
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(clipboardText, 'Hello');
    expect(controller.text, 'Hello world');

    await tester.tap(find.text('Cut'));
    await tester.pump();
    expect(controller.text, ' world');
    expect(controller.selection.isCollapsed, isTrue);

    controller.setSelection(const TextSelection.collapsed(offset: 0));
    controller.setSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
    await tester.pump();
    await tester.tap(find.text('Paste'));
    await tester.pump();
    expect(controller.text, 'Helloworld');
    controller.undo();
    expect(controller.text, ' world');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('mobile long press selects a word and opens the actions', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = PlainTextEditingController(text: 'Hello world');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrPlainTextEditor(
            controller: controller,
            typography: typography,
            cursorColor: Colors.black,
            selectionColor: Colors.blue,
            onTextChanged: (_) {},
            onSelectionChanged: (_) {},
            onShareSelectedText: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.longPressAt(const Offset(50, 12));
    await tester.pump();

    expect(controller.selection.isCollapsed, isFalse);
    expect(
      controller.text.substring(
        controller.selection.start,
        controller.selection.end,
      ),
      'Hello',
    );
    expect(find.text('Copy'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iOS selection offers the same mobile actions', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = PlainTextEditingController(text: 'Hello world');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrPlainTextEditor(
            controller: controller,
            typography: typography,
            cursorColor: Colors.black,
            selectionColor: Colors.blue,
            onTextChanged: (_) {},
            onSelectionChanged: (_) {},
            onShareSelectedText: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ZephyrPlainTextEditor));
    await tester.pump();
    controller.setSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    await tester.pump();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android caret handle appears after tap and drags the caret', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = PlainTextEditingController(text: 'Hello world');
    addTearDown(controller.dispose);
    const handle = ValueKey('mobile-caret-handle');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrPlainTextEditor(
            controller: controller,
            typography: typography,
            cursorColor: Colors.black,
            selectionColor: Colors.blue,
            onTextChanged: (_) {},
            onSelectionChanged: (_) {},
            onShareSelectedText: (_, _) async {},
          ),
        ),
      ),
    );
    expect(find.byKey(handle), findsNothing);

    await tester.tapAt(const Offset(18, 12));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(handle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-text-handle-visual')),
      findsOneWidget,
    );
    final before = controller.selection.extentOffset;

    final handlePosition = tester.getTopLeft(find.byKey(handle));
    final gesture = await tester.startGesture(
      handlePosition + const Offset(24, 11),
    );
    await gesture.moveBy(const Offset(75, 0));
    await tester.pump();
    expect(find.byType(Magnifier), findsOneWidget);
    expect(find.byKey(handle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-text-handle-visual')),
      findsNothing,
    );
    await gesture.up();
    await tester.pump();
    expect(find.byType(Magnifier), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-text-handle-visual')),
      findsOneWidget,
    );

    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.extentOffset, greaterThan(before));
    expect(find.byKey(handle), findsOneWidget);

    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '${controller.text}!',
        selection: TextSelection.collapsed(offset: controller.text.length + 1),
      ),
    );
    await tester.pump();
    expect(find.byKey(handle), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('mobile caret handle hides on scroll and focus loss', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = PlainTextEditingController(text: 'Hello world');
    addTearDown(controller.dispose);
    final otherFocus = FocusNode();
    addTearDown(otherFocus.dispose);
    const handle = ValueKey('mobile-caret-handle');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ZephyrPlainTextEditor(
                  controller: controller,
                  typography: typography,
                  cursorColor: Colors.black,
                  selectionColor: Colors.blue,
                  onTextChanged: (_) {},
                  onSelectionChanged: (_) {},
                  onShareSelectedText: (_, _) async {},
                ),
              ),
              TextField(focusNode: otherFocus),
            ],
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(18, 12));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(handle), findsOneWidget);

    final scrollGesture = await tester.startGesture(const Offset(300, 300));
    await scrollGesture.moveBy(const Offset(0, -80));
    await scrollGesture.up();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(handle), findsNothing);

    await tester.tap(find.byType(ZephyrPlainTextEditor));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(handle), findsOneWidget);
    otherFocus.requestFocus();
    await tester.pump();
    expect(find.byKey(handle), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
