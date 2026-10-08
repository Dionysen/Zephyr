import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/document/plain_text_document.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/editor_typography.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/plain_text_layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const typography = EditorTypography(
    color: Color(0xFF000000),
    fontSize: 20,
    lineHeight: 1.5,
    paragraphSpacing: 1.0,
    maxContentWidth: 400,
    documentPadding: EdgeInsets.zero,
  );

  test('applies paragraph spacing between paragraphs only', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    engine.update(
      document: const PlainTextDocument('A\nB\nC'),
      typography: typography,
      viewportWidth: 400,
    );

    expect(engine.metrics, hasLength(3));
    expect(engine.metrics[0].gapAfter, 20); // fontSize * paragraphSpacing
    expect(engine.metrics[1].gapAfter, 20);
    expect(engine.metrics[2].gapAfter, 0);

    final expectedSecondY =
        engine.metrics[0].contentHeight + engine.metrics[0].gapAfter;
    expect(engine.metrics[1].yOffset, expectedSecondY);
  });

  test('maps caret offsets into successive paragraphs', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    engine.update(
      document: const PlainTextDocument('Hi\nYo'),
      typography: typography,
      viewportWidth: 400,
    );

    final first = engine.caretRectForOffset(0);
    final second = engine.caretRectForOffset(3); // start of second paragraph
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(second!.top, greaterThan(first!.top));
  });

  test('centers the text column inside equal document padding', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    const padded = EditorTypography(
      color: Color(0xFF000000),
      fontSize: 20,
      lineHeight: 1.5,
      paragraphSpacing: 0.5,
      maxContentWidth: 400,
      documentPadding: EdgeInsets.fromLTRB(42, 28, 42, 48),
    );
    engine.update(
      document: const PlainTextDocument('Hello'),
      typography: padded,
      viewportWidth: 1000,
    );

    // Available = 1000 - 84 = 916; content = 400; leading = 258.
    expect(engine.contentWidth, 400);
    expect(engine.contentLeft, 42 + 258);
    expect(1000 - (engine.contentLeft + engine.contentWidth), 42 + 258);
  });

  test('visibleParagraphRange returns a band around the viewport', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    final buffer = StringBuffer();
    for (var i = 0; i < 40; i++) {
      if (i > 0) buffer.writeln();
      buffer.write('Paragraph $i');
    }
    engine.update(
      document: PlainTextDocument(buffer.toString()),
      typography: typography,
      viewportWidth: 400,
    );

    final (first, last) = engine.visibleParagraphRange(
      scrollOffset: engine.metrics[10].yOffset,
      viewportHeight: 100,
      overscan: 0,
    );
    expect(first, lessThanOrEqualTo(10));
    expect(last, greaterThanOrEqualTo(10));
    expect(last - first, lessThan(engine.metrics.length));
  });
}
