/// Ideographic space used for portable first-line indentation in plain text.
const ideographicSpace = '\u3000';

/// Builds a first-line indent prefix of [characters] ideographic spaces.
String ideographicIndent(int characters) =>
    ideographicSpace * characters.clamp(0, 0xFFFF);

/// Counts leading ideographic spaces on [line].
int leadingIdeographicIndentCount(String line) {
  var count = 0;
  for (final unit in line.runes) {
    if (unit != 0x3000) break;
    count += 1;
  }
  return count;
}

/// Applies first-line indentation with actual ideographic spaces instead of a
/// visual-only paragraph style, preserving portable plain-text documents.
String applyParagraphIndentation(String text, int characters) {
  final prefix = ideographicIndent(characters);
  return text
      .split('\n')
      .map((line) {
        final unindented = line.replaceFirst(RegExp(r'^　+'), '');
        return unindented.isEmpty ? unindented : '$prefix$unindented';
      })
      .join('\n');
}
