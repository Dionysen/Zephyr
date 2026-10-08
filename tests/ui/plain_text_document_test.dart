import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/document/plain_text_document.dart';

void main() {
  test('splits paragraphs on newlines and keeps empties', () {
    const source = 'First\n\nThird line';
    final document = PlainTextDocument(source);
    expect(document.paragraphs, ['First', '', 'Third line']);
    expect(document.paragraphStarts(), [0, 6, 7]);
  });

  test('empty text is a single empty paragraph', () {
    const document = PlainTextDocument('');
    expect(document.paragraphs, ['']);
    expect(document.paragraphStarts(), [0]);
  });

  test('replaceRange updates text', () {
    final next = const PlainTextDocument('Hello').replaceRange(0, 5, 'Hi');
    expect(next.text, 'Hi');
  });

  test('paragraphIndexForOffset maps through newlines', () {
    const document = PlainTextDocument('ab\ncd\ne');
    expect(document.paragraphIndexForOffset(0), 0);
    expect(document.paragraphIndexForOffset(3), 1);
    expect(document.paragraphIndexForOffset(6), 2);
  });
}
