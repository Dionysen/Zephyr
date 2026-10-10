import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/text_word_boundaries.dart';

void main() {
  test('wordBoundaryLeft skips separators then word', () {
    expect(wordBoundaryLeft('hello world', 11), 6);
    expect(wordBoundaryLeft('hello world', 6), 0);
    expect(wordBoundaryLeft('hello', 5), 0);
  });

  test('wordBoundaryRight advances across separators and words', () {
    expect(wordBoundaryRight('hello world', 0), 5);
    expect(wordBoundaryRight('hello world', 5), 11);
  });

  test('CJK characters count as word chars', () {
    expect(wordBoundaryLeft('你好世界', 4), 0);
    // Latin + CJK without separators form one word run.
    expect(wordBoundaryRight('ab你好', 0), 4);
    expect(wordBoundaryRight('ab 你好', 0), 2);
    expect(wordBoundaryRight('ab 你好', 2), 5);
  });
}
