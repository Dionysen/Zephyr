/// Plain-text document stored as a single UTF-16 [String].
///
/// Paragraphs are separated by `\n` (empty paragraphs are kept).
class PlainTextDocument {
  const PlainTextDocument(this.text);

  final String text;

  static const empty = PlainTextDocument('');

  int get length => text.length;

  /// Paragraph strings including empties. Never empty — `''` yields `['']`.
  List<String> get paragraphs {
    if (text.isEmpty) return const [''];
    return text.split('\n');
  }

  /// Start offset (UTF-16) of each paragraph in [text].
  List<int> paragraphStarts() {
    final paras = paragraphs;
    final starts = List<int>.filled(paras.length, 0);
    var offset = 0;
    for (var i = 0; i < paras.length; i++) {
      starts[i] = offset;
      offset += paras[i].length;
      if (i < paras.length - 1) offset += 1; // '\n'
    }
    return starts;
  }

  int paragraphIndexForOffset(int offset) {
    final clamped = offset.clamp(0, text.length);
    final starts = paragraphStarts();
    var index = 0;
    for (var i = 0; i < starts.length; i++) {
      if (starts[i] <= clamped) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  PlainTextDocument replaceRange(int start, int end, String replacement) {
    assert(start >= 0 && end >= start && end <= text.length);
    return PlainTextDocument(
      text.replaceRange(start, end, replacement),
    );
  }

  PlainTextDocument insert(int offset, String value) =>
      replaceRange(offset, offset, value);

  PlainTextDocument delete(int start, int end) =>
      replaceRange(start, end, '');
}
