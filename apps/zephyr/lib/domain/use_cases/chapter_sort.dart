import '../models/chapter_sort_mode.dart';
import '../models/purewriter_models.dart';

/// Returns a new list sorted by [mode]. [manual] preserves input order (rank).
List<ArticleSummary> sortArticleSummaries(
  List<ArticleSummary> articles,
  ChapterSortMode mode,
) {
  if (mode.isManual || articles.length <= 1) {
    return List<ArticleSummary>.from(articles, growable: false);
  }
  final sorted = List<ArticleSummary>.from(articles);
  sorted.sort((a, b) => _compare(a, b, mode));
  return sorted;
}

int _compare(ArticleSummary a, ArticleSummary b, ChapterSortMode mode) {
  final primary = switch (mode) {
    ChapterSortMode.manual => 0,
    ChapterSortMode.createdAsc => a.createdAt.compareTo(b.createdAt),
    ChapterSortMode.createdDesc => b.createdAt.compareTo(a.createdAt),
    ChapterSortMode.updatedAsc => a.updatedAt.compareTo(b.updatedAt),
    ChapterSortMode.updatedDesc => b.updatedAt.compareTo(a.updatedAt),
    ChapterSortMode.titleAsc => _titleKey(a).compareTo(_titleKey(b)),
    ChapterSortMode.titleDesc => _titleKey(b).compareTo(_titleKey(a)),
  };
  if (primary != 0) return primary;
  return a.id.compareTo(b.id);
}

String _titleKey(ArticleSummary article) => article.title.toLowerCase();
