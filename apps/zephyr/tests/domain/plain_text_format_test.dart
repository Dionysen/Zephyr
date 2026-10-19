import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/plain_text_format.dart';

void main() {
  test('normalizes indent and collapses extra blank lines', () {
    expect(
      formatPlainTextDocument('First\n\n\n\n　Second\n\n\nThird', 2),
      '　　First\n\n　　Second\n\n　　Third',
    );
  });

  test('leaves a single blank line between paragraphs', () {
    expect(
      formatPlainTextDocument('A\n\nB', 1),
      '　A\n\n　B',
    );
  });

  test('keep inserts a blank line between consecutive non-empty lines', () {
    expect(keepParagraphBlankLines('第一段\n第二段'), '第一段\n\n第二段');
    expect(keepParagraphBlankLines('A\n\nB'), 'A\n\nB');
    expect(keepParagraphBlankLines('A\n\n\nB'), 'A\n\nB');
  });

  test('remove strips blank lines between paragraphs', () {
    expect(removeParagraphBlankLines('第一段\n\n第二段'), '第一段\n第二段');
    expect(removeParagraphBlankLines('A\n\n\nB'), 'A\nB');
  });
}
