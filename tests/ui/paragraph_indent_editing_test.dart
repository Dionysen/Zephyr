import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:zephyr/ui/features/workspace/views/paragraph_indent_editing.dart';
import 'package:zephyr/ui/features/workspace/views/plain_text_document.dart';

void main() {
  test('Enter inherits leading ideographic indent from the previous paragraph', () {
    final document = documentFromPlainText('　　Hello');
    final editor = createZephyrDocumentEditor(document: document);
    final first = document.getNodeAt(0)! as TextNode;

    editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: first.id,
            nodePosition: TextNodePosition(offset: first.text.length),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      InsertNewlineAtCaretRequest(Editor.createNodeId()),
    ]);

    expect(document.nodeCount, 2);
    final newNode = document.getNodeAt(1)! as ParagraphNode;
    expect(newNode.text.toPlainText(), '　　');
    expect(
      editor.composer.selection,
      DocumentSelection.collapsed(
        position: DocumentPosition(
          nodeId: newNode.id,
          nodePosition: const TextNodePosition(offset: 2),
        ),
      ),
    );
  });

  test('Enter does not add indent when the previous paragraph has none', () {
    final document = documentFromPlainText('Hello');
    final editor = createZephyrDocumentEditor(document: document);
    final first = document.getNodeAt(0)! as TextNode;

    editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: first.id,
            nodePosition: TextNodePosition(offset: first.text.length),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      InsertNewlineAtCaretRequest(Editor.createNodeId()),
    ]);

    expect(
      (document.getNodeAt(1)! as ParagraphNode).text.toPlainText(),
      isEmpty,
    );
  });

  test('splitting mid-paragraph prefixes the carried text with inherited indent', () {
    final document = documentFromPlainText('　　HelloWorld');
    final editor = createZephyrDocumentEditor(document: document);
    final first = document.getNodeAt(0)! as TextNode;

    editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: first.id,
            // After "　　Hello"
            nodePosition: const TextNodePosition(offset: 7),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.userInteraction,
      ),
      InsertNewlineAtCaretRequest(Editor.createNodeId()),
    ]);

    expect(
      (document.getNodeAt(0)! as ParagraphNode).text.toPlainText(),
      '　　Hello',
    );
    expect(
      (document.getNodeAt(1)! as ParagraphNode).text.toPlainText(),
      '　　World',
    );
  });
}
