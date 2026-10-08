import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../domain/use_cases/paragraph_indentation.dart';

/// Creates a document editor that inherits first-line indent on newline.
Editor createZephyrDocumentEditor({required MutableDocument document}) {
  return Editor(
    editables: {
      Editor.documentKey: document,
      Editor.composerKey: MutableDocumentComposer(),
    },
    requestHandlers: List.from(defaultRequestHandlers),
    reactionPipeline: [
      const InheritFirstLineIndentReaction(),
      ...defaultEditorReactions,
    ],
  );
}

/// After a paragraph split, copies leading ideographic indent from the
/// previous paragraph into the newly inserted one.
class InheritFirstLineIndentReaction extends EditReaction {
  const InheritFirstLineIndentReaction();

  @override
  void modifyContent(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final insertedId = _insertedParagraphId(changeList);
    if (insertedId == null) return;

    final selection = editorContext.composer.selection;
    if (selection == null || !selection.isCollapsed) return;
    if (selection.extent.nodeId != insertedId) return;
    final caret = selection.extent.nodePosition;
    if (caret is! TextNodePosition || caret.offset != 0) return;

    final document = editorContext.document;
    final newNode = document.getNodeById(insertedId);
    if (newNode is! ParagraphNode) return;

    final previous = document.getNodeBeforeById(newNode.id);
    if (previous is! TextNode) return;

    final previousPlain = previous.text.toPlainText(includePlaceholders: false);
    final newPlain = newNode.text.toPlainText(includePlaceholders: false);
    final desired = leadingIdeographicIndentCount(previousPlain);
    final actual = leadingIdeographicIndentCount(newPlain);
    if (desired <= actual) return;

    final toInsert = ideographicIndent(desired - actual);
    requestDispatcher.execute([
      InsertTextRequest(
        documentPosition: DocumentPosition(
          nodeId: insertedId,
          nodePosition: const TextNodePosition(offset: 0),
        ),
        textToInsert: toInsert,
        attributions: const {},
      ),
    ]);
  }

  String? _insertedParagraphId(List<EditEvent> changeList) {
    String? id;
    for (final event in changeList) {
      if (event is! DocumentEdit) continue;
      final change = event.change;
      if (change is! NodeInsertedEvent) continue;
      // Prefer a single clear split; ignore multi-node inserts such as paste.
      if (id != null) return null;
      id = change.nodeId;
    }
    return id;
  }
}

/// Inserts the configured first-line indent width as ideographic spaces.
///
/// [indentCharacters] is read on each key press so preference changes apply
/// immediately without rebuilding the action list.
SuperEditorKeyboardAction tabToInsertFirstLineIndent(
  int Function() indentCharacters,
) {
  return ({
    required SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      return ExecutionInstruction.continueExecution;
    }
    if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
      return ExecutionInstruction.continueExecution;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return ExecutionInstruction.continueExecution;
    }

    final selection = editContext.composer.selection;
    if (selection == null) {
      return ExecutionInstruction.continueExecution;
    }
    if (selection.base.nodeId != selection.extent.nodeId) {
      return ExecutionInstruction.continueExecution;
    }

    final node = editContext.document.getNodeById(selection.extent.nodeId);
    if (node is! TextNode) {
      return ExecutionInstruction.continueExecution;
    }

    final indent = indentCharacters();
    if (indent > 0) {
      editContext.editor.execute([
        InsertPlainTextAtCaretRequest(ideographicIndent(indent)),
      ]);
    }

    // Halt even when indent is zero so Super Editor's visual indent metadata
    // does not diverge from the plain-text document.
    return ExecutionInstruction.haltExecution;
  };
}
