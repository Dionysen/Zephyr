class WritingFolder {
  const WritingFolder({
    required this.id,
    required this.name,
    required this.rank,
  });
  final String id;
  final String name;
  final int rank;
}

class ArticleSummary {
  const ArticleSummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.folderId,
    required this.categoryId,
    required this.updatedAt,
  });
  final String id;
  final String title;
  final String summary;
  final String folderId;
  final String? categoryId;
  final DateTime updatedAt;
}

class WritingArticle extends ArticleSummary {
  const WritingArticle({
    required super.id,
    required super.title,
    required super.summary,
    required super.folderId,
    required super.categoryId,
    required super.updatedAt,
    required this.content,
  });
  final String content;
}

class WritingLibrary {
  const WritingLibrary({required this.folders, required this.articles});
  final List<WritingFolder> folders;
  final List<ArticleSummary> articles;
}
