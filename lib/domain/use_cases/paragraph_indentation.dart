/// Applies first-line indentation with actual ideographic spaces instead of a
/// visual-only paragraph style, preserving portable plain-text documents.
String applyParagraphIndentation(String text, int characters) {
  final prefix = '\u3000' * characters;
  return text
      .split('\n')
      .map((line) {
        final unindented = line.replaceFirst(RegExp(r'^　+'), '');
        return unindented.isEmpty ? unindented : '$prefix$unindented';
      })
      .join('\n');
}
