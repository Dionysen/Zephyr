import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:zephyr/ui/features/workspace/views/plain_text_document.dart';

void main() {
  test('round-trips plain text through document nodes', () {
    const source = 'First\n\nThird line';
    final document = documentFromPlainText(source);
    expect(document.nodeCount, 3);
    expect(plainTextFromDocument(document), source);
  });

  test('empty text becomes a single empty paragraph', () {
    final document = documentFromPlainText('');
    expect(document.nodeCount, 1);
    expect(document.getNodeAt(0), isA<ParagraphNode>());
    expect(plainTextFromDocument(document), '');
  });

  test('preserves ideographic indent spaces', () {
    const source = '　　Indented\nNext';
    expect(plainTextFromDocument(documentFromPlainText(source)), source);
  });
}
