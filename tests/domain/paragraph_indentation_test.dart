import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/paragraph_indentation.dart';

void main() {
  test('uses ideographic spaces for each nonempty paragraph', () {
    expect(
      applyParagraphIndentation('First\n\n　Second', 2),
      '　　First\n\n　　Second',
    );
  });

  test('removes indentation when the preference is zero', () {
    expect(applyParagraphIndentation('　　First\n　Second', 0), 'First\nSecond');
  });
}
