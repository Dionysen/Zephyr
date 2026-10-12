import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/document/plain_text_document.dart';
import 'package:zephyr/ui/features/editor/plain_text/gestures/plain_text_gesture_handler.dart';
import 'package:zephyr/ui/features/editor/plain_text/input/plain_text_editing_controller.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/editor_typography.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/plain_text_layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlainTextEditingController controller;
  late PlainTextLayoutEngine engine;
  late PlainTextGestureHandler handler;
  late int changes;

  setUp(() {
    controller = PlainTextEditingController(text: 'hello world\nsecond');
    engine = PlainTextLayoutEngine();
    engine.update(
      document: const PlainTextDocument('hello world\nsecond'),
      typography: const EditorTypography(
        color: Color(0xFF000000),
        fontSize: 20,
        lineHeight: 1.5,
        paragraphSpacing: 0.5,
        marginLeft: 0,
        marginRight: 0,
        paddingTop: 0,
        paddingBottom: 0,
      ),
      viewportWidth: 400,
    );
    changes = 0;
    handler = PlainTextGestureHandler(
      controller: controller,
      engine: engine,
      onChanged: () => changes++,
      documentToGlobal: (local) => local,
    );
    addTearDown(() {
      controller.dispose();
      engine.dispose();
    });
  });

  Offset at(int offset) {
    final rect = engine.caretRectForOffset(offset)!;
    return Offset(rect.left, rect.center.dy);
  }

  test('drag selection preserves its anchor while extending the caret', () {
    final start = at(1);
    final end = at(8);
    handler.handleDragStart(start);
    expect(controller.selection.isCollapsed, isTrue);

    handler.handleDragUpdate(end, selecting: true);
    expect(controller.selection.baseOffset, engine.offsetForPosition(start));
    expect(controller.selection.extentOffset, engine.offsetForPosition(end));
    expect(changes, 2);
  });

  test('drag without selection moves the caret instead of extending it', () {
    handler.handleDragStart(at(1));
    handler.handleDragUpdate(at(8), selecting: false);

    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, engine.offsetForPosition(at(8)));
  });

  test('repeated taps select the word then the paragraph', () {
    final position = at(2);
    final details = TapDownDetails(localPosition: position);

    handler.handleTapDown(details, position);
    expect(controller.selection.isCollapsed, isTrue);
    handler.handleTapDown(details, position);
    expect(controller.selection.start, 0);
    expect(controller.selection.end, 5);
    handler.handleTapDown(details, position);
    expect(controller.selection.start, 0);
    expect(controller.selection.end, 11);
    expect(changes, 3);
  });
}
