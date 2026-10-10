import 'paragraph_indentation.dart';

/// One-tap format: normalize first-line indent and collapse extra blank lines.
String formatPlainTextDocument(String text, int firstLineIndent) {
  final indented = applyParagraphIndentation(text, firstLineIndent);
  return indented.replaceAll(RegExp(r'\n{3,}'), '\n\n');
}
