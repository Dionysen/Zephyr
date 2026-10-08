import 'package:super_editor/super_editor.dart';

/// Builds a [MutableDocument] where each plain-text line is a [ParagraphNode].
MutableDocument documentFromPlainText(String text) {
  final lines = text.isEmpty ? <String>[''] : text.split('\n');
  return MutableDocument(
    nodes: [
      for (final line in lines)
        ParagraphNode(id: Editor.createNodeId(), text: AttributedText(line)),
    ],
  );
}

/// Serializes a Super Editor [Document] back to newline-separated plain text.
String plainTextFromDocument(Document document) {
  final buffer = StringBuffer();
  for (var index = 0; index < document.nodeCount; index++) {
    if (index > 0) buffer.write('\n');
    final node = document.getNodeAt(index);
    if (node is TextNode) {
      buffer.write(node.text.toPlainText(includePlaceholders: false));
    }
  }
  return buffer.toString();
}
