import 'package:flutter/services.dart';

/// Opening → closing pairs for wrap-on-insert punctuation.
const pairedPunctuationClosers = <String, String>{
  '\u201c': '\u201d', // “ ”
  '\u2018': '\u2019', // ‘ ’
  '"': '"',
  "'": "'",
  '「': '」',
  '『': '』',
  '《': '》',
  '〈': '〉',
  '（': '）',
  '(': ')',
  '【': '】',
  '[': ']',
  '{': '}',
  '〔': '〕',
  '〖': '〗',
};

/// Quotes / corner quotes that sit in a wide cell with empty side bearing.
const visuallyNarrowPairedOpeners = <String>{
  '\u201c',
  '\u2018',
  '"',
  "'",
  '「',
  '『',
};

/// Resolved pair ready to insert as [open][close] with caret between.
class PairedPunctuationInsert {
  const PairedPunctuationInsert({required this.open, required this.close});

  final String open;
  final String close;

  String get text => '$open$close';

  bool get isVisuallyNarrow => visuallyNarrowPairedOpeners.contains(open);
}

/// Active wrap highlight after a pair was just inserted (one-shot).
class PairedPunctuationSession {
  PairedPunctuationSession({
    required this.openIndex,
    required this.closeIndex,
    required this.openChar,
    required this.closeChar,
  });

  int openIndex;
  int closeIndex;
  final String openChar;
  final String closeChar;

  int get highlightEnd => closeIndex + closeChar.length;

  /// Content between opener and closer (excludes the punctuation glyphs).
  int get interiorStart => openIndex + openChar.length;
  int get interiorEnd => closeIndex;

  /// True when there is no content between the opener and closer.
  bool get isEmptyInterior => closeIndex == openIndex + openChar.length;

  bool get isVisuallyNarrow => visuallyNarrowPairedOpeners.contains(openChar);

  bool matches(String text) {
    if (openIndex < 0 || closeIndex <= openIndex) return false;
    if (highlightEnd > text.length) return false;
    return text.substring(openIndex, openIndex + openChar.length) == openChar &&
        text.substring(closeIndex, closeIndex + closeChar.length) == closeChar;
  }

  /// Whether [selection] lies entirely between the pair glyphs.
  bool containsSelection(TextSelection selection) {
    return selection.start >= interiorStart && selection.end <= interiorEnd;
  }
}

/// Inclusive diff of [before] → [after] as replace ranges.
class TextEditRange {
  const TextEditRange({
    required this.beforeStart,
    required this.beforeEnd,
    required this.afterStart,
    required this.afterEnd,
  });

  final int beforeStart;
  final int beforeEnd;
  final int afterStart;
  final int afterEnd;

  String insertedIn(String after) => after.substring(afterStart, afterEnd);
}

TextEditRange? findTextEditRange(String before, String after) {
  if (before == after) return null;
  var start = 0;
  final minLen = before.length < after.length ? before.length : after.length;
  while (start < minLen && before.codeUnitAt(start) == after.codeUnitAt(start)) {
    start++;
  }
  var beforeEnd = before.length;
  var afterEnd = after.length;
  while (beforeEnd > start &&
      afterEnd > start &&
      before.codeUnitAt(beforeEnd - 1) == after.codeUnitAt(afterEnd - 1)) {
    beforeEnd--;
    afterEnd--;
  }
  return TextEditRange(
    beforeStart: start,
    beforeEnd: beforeEnd,
    afterStart: start,
    afterEnd: afterEnd,
  );
}

/// When an empty wrap's opener was deleted, returns the orphaned closer range
/// that should also be removed. Otherwise null.
({int start, int end})? orphanCloserRangeAfterEmptyOpenDeleted({
  required PairedPunctuationSession session,
  required String before,
  required String after,
}) {
  if (!session.isEmptyInterior || !session.matches(before)) return null;
  final removed = session.openChar.length;
  if (after.length != before.length - removed) return null;
  final at = session.openIndex;
  if (at < 0 || at + session.closeChar.length > after.length) return null;
  if (after.substring(at, at + session.closeChar.length) != session.closeChar) {
    return null;
  }
  // Opener gone, closer slid into its place.
  return (start: at, end: at + session.closeChar.length);
}

/// Returns a pair insert when [payload] is a single opener or a full pair.
/// Otherwise null (normal phrase insert).
PairedPunctuationInsert? resolvePairedPunctuationInsert(String payload) {
  final raw = payload;
  if (raw.isEmpty) return null;

  // Full pair already: opener + matching closer (2 code units / typical case).
  if (raw.length >= 2) {
    for (final entry in pairedPunctuationClosers.entries) {
      final open = entry.key;
      final close = entry.value;
      if (raw == '$open$close') {
        return PairedPunctuationInsert(open: open, close: close);
      }
    }
  }

  // Single opener (or payload that is exactly an opener).
  final closer = pairedPunctuationClosers[raw];
  if (closer != null) {
    return PairedPunctuationInsert(open: raw, close: closer);
  }

  return null;
}

/// Detects a typed/pasted opener or full pair that should start a wrap session.
///
/// Distinguishes a lone opener (`“` → needs closer) from an already-complete
/// pair (`“”` → caret between, do not add another closer). Also accepts IME
/// composing commits that replace a short range with the pair payload.
({PairedPunctuationInsert pair, int openIndex, bool needsCloser})?
detectTypedPairedPunctuation({
  required String before,
  required String after,
}) {
  final edit = findTextEditRange(before, after);
  if (edit == null) return null;
  final inserted = edit.insertedIn(after);
  final pair = resolvePairedPunctuationInsert(inserted);
  if (pair == null) return null;
  // Reject large replacements (paste of prose that happens to start with a
  // quote); allow pure inserts and short composing commits.
  final deleted = edit.beforeEnd - edit.beforeStart;
  if (deleted > 0 && deleted > inserted.length) return null;
  if (inserted == pair.open) {
    return (pair: pair, openIndex: edit.afterStart, needsCloser: true);
  }
  if (inserted == pair.text) {
    return (pair: pair, openIndex: edit.afterStart, needsCloser: false);
  }
  return null;
}

/// Whether inserting [closer] at [offset] would duplicate an empty pair that
/// is already present (`“|”` + `”` → skip).
bool isRedundantPairedCloserInsert({
  required String text,
  required int offset,
  required String closer,
}) {
  for (final entry in pairedPunctuationClosers.entries) {
    if (entry.value != closer) continue;
    final open = entry.key;
    final close = entry.value;
    if (offset < open.length) continue;
    if (text.substring(offset - open.length, offset) != open) continue;
    if (offset + close.length > text.length) continue;
    if (text.substring(offset, offset + close.length) != close) continue;
    return true;
  }
  // IME may also try to append the closer after a pair we already expanded.
  for (final entry in pairedPunctuationClosers.entries) {
    if (entry.value != closer) continue;
    final open = entry.key;
    final close = entry.value;
    final pairLen = open.length + close.length;
    if (offset < pairLen) continue;
    if (text.substring(offset - pairLen, offset) != '$open$close') continue;
    return true;
  }
  return false;
}

/// Maps [session] indices through a text replacement from [before] to [after].
/// Returns null when the pair anchors were destroyed.
PairedPunctuationSession? remapPairedPunctuationSession(
  PairedPunctuationSession session,
  String before,
  String after,
) {
  if (before == after) return session;
  if (!session.matches(before)) return null;

  final edit = findTextEditRange(before, after);
  if (edit == null) return session;

  int? mapAnchor(int index, int anchorLength) {
    final anchorEnd = index + anchorLength;
    // Fully before the edit.
    if (anchorEnd <= edit.beforeStart) return index;
    // Fully after the edit.
    if (index >= edit.beforeEnd) {
      return index + (edit.afterEnd - edit.beforeEnd);
    }
    // Overlaps the replaced region — pair broken.
    return null;
  }

  final open = mapAnchor(session.openIndex, session.openChar.length);
  final close = mapAnchor(session.closeIndex, session.closeChar.length);
  if (open == null || close == null || close <= open) return null;

  final next = PairedPunctuationSession(
    openIndex: open,
    closeIndex: close,
    openChar: session.openChar,
    closeChar: session.closeChar,
  );
  return next.matches(after) ? next : null;
}
