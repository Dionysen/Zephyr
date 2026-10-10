/// PureWriter-compatible sidebar / DB `summary` from article content.
///
/// Normalizes newlines to spaces, then keeps the first 200 UTF-16 runes.
String articlePreviewSummary(String content) => content
    .replaceAll(RegExp(r'[\r\n]+'), ' ')
    .trim()
    .runes
    .take(200)
    .map(String.fromCharCode)
    .join();
