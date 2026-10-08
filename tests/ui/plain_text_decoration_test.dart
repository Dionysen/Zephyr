import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/decoration/text_decoration_model.dart';
import 'package:zephyr/ui/features/editor/plain_text/document/plain_text_document.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/editor_typography.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/plain_text_layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decoration ranges resolve to non-empty boxes for selected text', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    engine.update(
      document: const PlainTextDocument('Hello\nWorld'),
      typography: const EditorTypography(
        color: Color(0xFF000000),
        fontSize: 18,
        lineHeight: 1.5,
        paragraphSpacing: 0.5,
        maxContentWidth: 400,
        documentPadding: EdgeInsets.zero,
      ),
      viewportWidth: 400,
    );

    const decoration = TextSpanDecoration(
      start: 0,
      end: 5,
      background: Color(0x33FF0000),
      borderColor: Color(0xFFFF0000),
    );
    final boxes = engine.boxesForRange(decoration.start, decoration.end);
    expect(boxes, isNotEmpty);
    expect(boxes.first.width, greaterThan(0));
  });
}
