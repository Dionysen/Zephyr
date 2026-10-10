/// Simple Unicode-aware word boundaries for plain-text navigation.
///
/// A "word" character is a letter or decimal digit (including CJK letters).
/// Everything else (whitespace, punctuation) is a separator.
bool isWordChar(int rune) {
  if (rune >= 0x30 && rune <= 0x39) return true; // 0-9
  if (rune >= 0x41 && rune <= 0x5A) return true; // A-Z
  if (rune >= 0x61 && rune <= 0x7A) return true; // a-z
  if (rune >= 0x4E00 && rune <= 0x9FFF) return true;
  if (rune >= 0x3400 && rune <= 0x4DBF) return true;
  if (rune >= 0x3040 && rune <= 0x30FF) return true;
  if (rune >= 0xAC00 && rune <= 0xD7AF) return true;
  if (rune >= 0xFF10 && rune <= 0xFF19) return true;
  if (rune >= 0xFF21 && rune <= 0xFF3A) return true;
  if (rune >= 0xFF41 && rune <= 0xFF5A) return true;
  return false;
}

({int start, int end, int rune})? _runeEndingAt(String text, int end) {
  if (end <= 0 || end > text.length) return null;
  if (end >= 2) {
    final lead = text.codeUnitAt(end - 2);
    final trail = text.codeUnitAt(end - 1);
    if (lead >= 0xD800 &&
        lead <= 0xDBFF &&
        trail >= 0xDC00 &&
        trail <= 0xDFFF) {
      return (
        start: end - 2,
        end: end,
        rune: ((lead - 0xD800) << 10) + (trail - 0xDC00) + 0x10000,
      );
    }
  }
  return (start: end - 1, end: end, rune: text.codeUnitAt(end - 1));
}

({int start, int end, int rune})? _runeStartingAt(String text, int start) {
  if (start < 0 || start >= text.length) return null;
  final unit = text.codeUnitAt(start);
  if (unit >= 0xD800 && unit <= 0xDBFF && start + 1 < text.length) {
    final trail = text.codeUnitAt(start + 1);
    if (trail >= 0xDC00 && trail <= 0xDFFF) {
      return (
        start: start,
        end: start + 2,
        rune: ((unit - 0xD800) << 10) + (trail - 0xDC00) + 0x10000,
      );
    }
  }
  return (start: start, end: start + 1, rune: unit);
}

/// Moves left to the start of the previous/current word.
int wordBoundaryLeft(String text, int offset) {
  var i = offset.clamp(0, text.length);
  if (i == 0) return 0;
  // Skip separators.
  while (i > 0) {
    final r = _runeEndingAt(text, i);
    if (r == null) break;
    if (isWordChar(r.rune)) break;
    i = r.start;
  }
  // Skip word chars.
  while (i > 0) {
    final r = _runeEndingAt(text, i);
    if (r == null) break;
    if (!isWordChar(r.rune)) break;
    i = r.start;
  }
  return i;
}

/// Moves right past the next/current word.
int wordBoundaryRight(String text, int offset) {
  var i = offset.clamp(0, text.length);
  final len = text.length;
  if (i >= len) return len;
  while (i < len) {
    final r = _runeStartingAt(text, i);
    if (r == null) break;
    if (isWordChar(r.rune)) break;
    i = r.end;
  }
  while (i < len) {
    final r = _runeStartingAt(text, i);
    if (r == null) break;
    if (!isWordChar(r.rune)) break;
    i = r.end;
  }
  return i;
}
