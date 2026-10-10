/// One match from [searchArticles] (UTF-16 indices into content, or title-only).
class ArticleSearchMatch {
  const ArticleSearchMatch({
    required this.articleId,
    required this.title,
    required this.folderId,
    required this.categoryId,
    required this.query,
    this.contentStart,
    this.contentEnd,
    this.snippet = '',
    this.snippetHighlightStart = 0,
    this.snippetHighlightEnd = 0,
  });

  final String articleId;
  final String title;
  final String folderId;
  final String? categoryId;

  /// Original trimmed query string used for the search.
  final String query;

  /// UTF-16 `[contentStart, contentEnd)` in article content; null = title-only.
  final int? contentStart;
  final int? contentEnd;

  /// Context around the match for list display (newlines collapsed).
  final String snippet;
  final int snippetHighlightStart;
  final int snippetHighlightEnd;

  bool get isTitleOnly => contentStart == null || contentEnd == null;
}

/// Case-insensitive substring search over [articles]' titles and bodies.
///
/// Content matches use UTF-16 indices compatible with Flutter text editing.
/// Each content occurrence is a separate result; a title match is emitted once
/// per article when the title contains [query].
List<ArticleSearchMatch> searchArticles({
  required List<
          ({
            String id,
            String title,
            String content,
            String folderId,
            String? categoryId
          })>
      articles,
  required String query,
  int snippetRadius = 28,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];

  final needle = trimmed.toLowerCase();
  final results = <ArticleSearchMatch>[];

  for (final article in articles) {
    final titleLower = article.title.toLowerCase();
    if (titleLower.contains(needle)) {
      final titleIndex = titleLower.indexOf(needle);
      results.add(
        ArticleSearchMatch(
          articleId: article.id,
          title: article.title,
          folderId: article.folderId,
          categoryId: article.categoryId,
          query: trimmed,
          snippet: article.title,
          snippetHighlightStart: titleIndex,
          snippetHighlightEnd: titleIndex + trimmed.length,
        ),
      );
    }

    final content = article.content;
    final contentLower = content.toLowerCase();
    var from = 0;
    while (true) {
      final index = contentLower.indexOf(needle, from);
      if (index < 0) break;
      final end = index + trimmed.length;
      final snippet = _snippetAround(
        content,
        index,
        end,
        radius: snippetRadius,
      );
      results.add(
        ArticleSearchMatch(
          articleId: article.id,
          title: article.title,
          folderId: article.folderId,
          categoryId: article.categoryId,
          query: trimmed,
          contentStart: index,
          contentEnd: end,
          snippet: snippet.text,
          snippetHighlightStart: snippet.highlightStart,
          snippetHighlightEnd: snippet.highlightEnd,
        ),
      );
      from = index + trimmed.length;
      if (from >= contentLower.length) break;
    }
  }

  return results;
}

({String text, int highlightStart, int highlightEnd}) _snippetAround(
  String content,
  int start,
  int end, {
  required int radius,
}) {
  final from = (start - radius).clamp(0, content.length);
  final to = (end + radius).clamp(0, content.length);
  String collapse(String value) => value.replaceAll(RegExp(r'[\r\n]+'), ' ');
  final before = collapse(content.substring(from, start));
  final match = collapse(content.substring(start, end));
  final after = collapse(content.substring(end, to));
  final prefix = from > 0 ? '…' : '';
  final suffix = to < content.length ? '…' : '';
  return (
    text: '$prefix$before$match$after$suffix',
    highlightStart: prefix.length + before.length,
    highlightEnd: prefix.length + before.length + match.length,
  );
}
