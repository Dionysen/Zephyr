/// Counts characters the same way PureWriter / Zephyr store [wordCount]:
/// every rune except CR/LF.
int countPlainTextWords(String text) =>
    text.runes.where((rune) => rune != 10 && rune != 13).length;

/// Overlay label: total when unfocused; `before / total` at the caret when focused.
String plainTextWordCountLabel({
  required String text,
  required int caretOffset,
  required bool focused,
}) {
  final total = countPlainTextWords(text);
  if (!focused) return '$total';
  final end = caretOffset.clamp(0, text.length);
  final before = countPlainTextWords(text.substring(0, end));
  return '$before / $total';
}
