import 'package:flutter_test/flutter_test.dart';
import 'package:text_editor_foundation/text/three_way_text_merge.dart';

void main() {
  test('merge keeps edits on different lines', () {
    final merged = mergeDivergedText(
      base: '共同正文',
      local: '共同正文\n乙加了一段',
      remote: '共同正文\n甲加了一段',
    );

    expect(merged.hasConflict, isFalse);
    expect(merged.text, contains('甲加了一段'));
    expect(merged.text, contains('乙加了一段'));
  });

  test('merge concatenates text appended to the same paragraph', () {
    final merged = mergeDivergedText(base: '正文', local: '正文。乙', remote: '正文。甲');

    expect(merged.hasConflict, isFalse);
    expect(merged.text, '正文。乙。甲');
  });

  test('merge keeps both replacements of the same sentence', () {
    final merged = mergeDivergedText(base: '原句', local: '乙改过', remote: '甲改过');

    expect(merged.hasConflict, isTrue);
    expect(merged.text, contains('乙改过'));
    expect(merged.text, contains('甲改过'));
    expect(merged.text, contains(localConflictStart));
  });

  test('unchanged side contributes nothing new', () {
    expect(
      mergeDivergedText(base: '正文', local: '正文', remote: '正文\n甲').text,
      '正文\n甲',
    );
  });
}
