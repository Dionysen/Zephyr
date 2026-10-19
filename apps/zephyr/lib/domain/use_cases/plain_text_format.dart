import 'package:text_editor_foundation/text/paragraph_indentation.dart';

import '../models/plain_text_format_option.dart';
import 'plain_text_zh_convert.dart';

/// One-tap format: normalize first-line indent and collapse extra blank lines.
String formatPlainTextDocument(String text, int firstLineIndent) {
  return applyPlainTextFormat(
    text,
    options: const {
      PlainTextFormatOption.keepParagraphBlanks,
      PlainTextFormatOption.addParagraphIndent,
    },
    firstLineIndent: firstLineIndent,
  );
}

/// Applies [options] in a stable pipeline order.
String applyPlainTextFormat(
  String text, {
  required Set<PlainTextFormatOption> options,
  required int firstLineIndent,
}) {
  var out = text;
  if (options.contains(PlainTextFormatOption.removeParagraphBlanks)) {
    out = removeParagraphBlankLines(out);
  } else if (options.contains(PlainTextFormatOption.keepParagraphBlanks)) {
    out = keepParagraphBlankLines(out);
  }
  if (options.contains(PlainTextFormatOption.insertCjkLatinSpaces)) {
    out = insertSpacesBetweenCjkAndLatin(out);
  }
  if (options.contains(PlainTextFormatOption.removeParagraphIndent)) {
    out = removeParagraphIndentation(out);
  } else if (options.contains(PlainTextFormatOption.addParagraphIndent)) {
    out = applyParagraphIndentation(out, firstLineIndent);
  }
  if (options.contains(PlainTextFormatOption.halfwidthToFullwidth)) {
    out = halfwidthAsciiToFullwidth(out);
  }
  if (options.contains(PlainTextFormatOption.simplifiedToTraditional)) {
    out = PlainTextZhConverter.simplifiedToTraditional(out);
  } else if (options.contains(PlainTextFormatOption.traditionalToSimplified)) {
    out = PlainTextZhConverter.traditionalToSimplified(out);
  }
  return out;
}

String applySinglePlainTextFormat(
  String text,
  PlainTextFormatOption option, {
  required int firstLineIndent,
}) =>
    applyPlainTextFormat(
      text,
      options: {option},
      firstLineIndent: firstLineIndent,
    );

/// Ensures a single blank line between non-empty lines (paragraphs).
///
/// Collapses runs of 3+ newlines first, then inserts a blank line between
/// consecutive non-empty lines that were only separated by a single newline.
String keepParagraphBlankLines(String text) {
  if (text.isEmpty) return text;
  final lines = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').split('\n');
  final out = <String>[];
  for (final line in lines) {
    if (line.trim().isEmpty) {
      if (out.isEmpty || out.last.isNotEmpty) {
        out.add('');
      }
      continue;
    }
    if (out.isNotEmpty && out.last.isNotEmpty) {
      out.add('');
    }
    out.add(line);
  }
  return out.join('\n');
}

/// Removes blank lines between paragraphs (non-empty lines stay on separate lines).
String removeParagraphBlankLines(String text) => text
    .split('\n')
    .where((line) => line.trim().isNotEmpty)
    .join('\n');

/// Inserts a single ASCII space between Han and Latin/number runs.
String insertSpacesBetweenCjkAndLatin(String text) {
  var out = text;
  out = out.replaceAllMapped(
    RegExp(r'([\u4e00-\u9fff])([A-Za-z0-9])'),
    (m) => '${m[1]} ${m[2]}',
  );
  out = out.replaceAllMapped(
    RegExp(r'([A-Za-z0-9])([\u4e00-\u9fff])'),
    (m) => '${m[1]} ${m[2]}',
  );
  return out.replaceAll(RegExp(r' {2,}'), ' ');
}

String removeParagraphIndentation(String text) => text
    .split('\n')
    .map((line) => line.replaceFirst(RegExp(r'^　+'), ''))
    .join('\n');

/// Maps ASCII punctuation and space to fullwidth forms.
String halfwidthAsciiToFullwidth(String text) => text.replaceAllMapped(
  RegExp(r'[ -~]'),
  (m) {
    final code = m.group(0)!.codeUnitAt(0);
    if (code == 0x20) return ideographicSpace;
    return String.fromCharCode(code + 0xFEE0);
  },
);
