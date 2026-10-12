import 'package:flutter/material.dart';
import 'package:flutter_primitives/flutter_primitives.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plain_text_editor/plain_text_editor.dart';
import 'package:text_editor_foundation/text_editor_foundation.dart' as foundation;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'public editor package exposes editable document and layout margins',
    () {
      final controller = PlainTextEditingController(text: 'one');
      addTearDown(controller.dispose);

      controller.insertText('two', coalesce: false);

      expect(controller.text, 'twoone');
      expect(controller.selection.baseOffset, 3);
      expect(
        EditorMargins.resolveCentered(
          viewportWidth: 400,
          desiredContentWidth: 300,
        ).left,
        50,
      );
    },
  );

  test('shared breakpoints switch at the compact boundary', () {
    expect(AdaptiveBreakpoints.isCompact(719), isTrue);
    expect(AdaptiveBreakpoints.isCompact(720), isFalse);
  });

  test('pure Dart foundation applies paragraph indentation independently', () {
    expect(foundation.applyParagraphIndentation('A\nB', 1), '　A\n　B');
    expect(
      foundation.EditorMargins.resolveCentered(
        viewportWidth: 100,
        desiredContentWidth: 200,
      ).contentWidth,
      100,
    );
  });

  testWidgets('shared resize handle reports cumulative pointer movement', (
    tester,
  ) async {
    final updates = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 100,
              child: ColumnResizeHandle(
                onDragStart: () {},
                onDragUpdate: updates.add,
                onDragEnd: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ColumnResizeHandle)),
    );
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(15, 0));
    await gesture.up();

    expect(updates, isNotEmpty);
    expect(updates.last, 35);
  });

  testWidgets('nested navigator consumes back before exiting its host', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NestedBackNavigator(
          onExit: () => exits++,
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => Scaffold(
              body: settings.name == '/details'
                  ? const Text('Details')
                  : TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/details'),
                      child: const Text('Open details'),
                    ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);

    // Simulate the platform back callback delivered to the app binding.
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open details'), findsOneWidget);
    expect(exits, 0);

    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 1);
  });
}
