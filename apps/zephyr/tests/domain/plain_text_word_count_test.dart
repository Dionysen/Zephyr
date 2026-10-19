import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/plain_text_word_count.dart';

void main() {
  group('countPlainTextWords', () {
    test('ignores newlines', () {
      expect(countPlainTextWords('ab\ncd\r\nef'), 6);
    });

    test('counts CJK and ascii runes', () {
      expect(countPlainTextWords('你好Hi'), 4);
    });
  });

  group('plainTextWordCountLabel', () {
    test('unfocused shows total only', () {
      expect(
        plainTextWordCountLabel(
          text: 'hello\nworld',
          caretOffset: 3,
          focused: false,
        ),
        '10',
      );
    });

    test('focused shows caret prefix over total', () {
      expect(
        plainTextWordCountLabel(
          text: 'hello\nworld',
          caretOffset: 5,
          focused: true,
        ),
        '5 / 10',
      );
    });

    test('clamps caret past end', () {
      expect(
        plainTextWordCountLabel(
          text: 'abc',
          caretOffset: 99,
          focused: true,
        ),
        '3 / 3',
      );
    });
  });
}
