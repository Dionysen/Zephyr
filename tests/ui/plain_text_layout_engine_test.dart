import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_margins.dart';
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
    marginLeft: 0,
    marginRight: 0,
    paddingTop: 0,
    paddingBottom: 0,
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

  test('uses preferred margins when they fit', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    const padded = EditorTypography(
      color: Color(0xFF000000),
      fontSize: 20,
      lineHeight: 1.5,
      paragraphSpacing: 0.5,
      marginLeft: 40,
      marginRight: 20,
      paddingTop: 0,
      paddingBottom: 0,
    );
    engine.update(
      document: const PlainTextDocument('Hello'),
      typography: padded,
      viewportWidth: 400,
    );

    expect(engine.contentLeft, 40);
    expect(engine.contentWidth, 340);
    expect(400 - (engine.contentLeft + engine.contentWidth), 20);
  });

  test('equal margins are equal to both screen edges', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    const padded = EditorTypography(
      color: Color(0xFF000000),
      fontSize: 20,
      lineHeight: 1.5,
      paragraphSpacing: 0.5,
      marginLeft: 24,
      marginRight: 24,
      paddingTop: 0,
      paddingBottom: 0,
    );
    engine.update(
      document: const PlainTextDocument('Hello'),
      typography: padded,
      viewportWidth: 400,
    );

    final rightClear = 400 - (engine.contentLeft + engine.contentWidth);
    expect(engine.contentLeft, rightClear);
    expect(engine.contentLeft, 24);
  });

  test('equal margins stay strictly equal when scaled down', () {
    final margins = EditorMargins.resolve(
      viewportWidth: 200,
      desiredLeft: 80,
      desiredRight: 80,
      minContentWidth: 120,
    );
    expect(margins.left, margins.right);
    expect(margins.left + margins.right + margins.contentWidth, 200);
    expect(margins.contentWidth, 120);
  });

  test('unequal margins keep their ratio when scaled down', () {
    final margins = EditorMargins.resolve(
      viewportWidth: 200,
      desiredLeft: 80,
      desiredRight: 40,
      minContentWidth: 120,
    );
    expect(margins.contentWidth, 120);
    expect(margins.left / margins.right, closeTo(2, 1e-9));
  });

  test('visibleParagraphRange returns a band around the viewport', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    final buffer = StringBuffer();
    for (var i = 0; i < 40; i++) {
      buffer.writeln('Paragraph $i with enough text to wrap a little.');
    }
    engine.update(
      document: PlainTextDocument(buffer.toString()),
      typography: typography,
      viewportWidth: 400,
    );

    final (start, end) = engine.visibleParagraphRange(
      scrollOffset: 200,
      viewportHeight: 300,
      overscan: 50,
    );
    expect(start, lessThanOrEqualTo(end));
    expect(start, greaterThanOrEqualTo(0));
    expect(end, lessThan(engine.metrics.length));
  });
}
