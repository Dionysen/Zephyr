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
}
