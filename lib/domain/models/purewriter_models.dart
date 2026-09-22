/// Raised when another Zephyr process currently owns a library's write lock.
class LibraryInUseException implements Exception {
  const LibraryInUseException(this.libraryPath);

  final String libraryPath;
}

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

class WritingCategory {
  const WritingCategory({
    required this.id,
    required this.folderId,
    required this.name,
    required this.rank,
    required this.collapsed,
  });
  final String id;
  final String folderId;
  final String name;
  final int rank;
  final bool collapsed;
}

class SchemaStatus {
  const SchemaStatus({
    required this.userVersion,
    required this.identityHash,
    required this.writesAllowed,
  });
  final int userVersion;
  final String identityHash;
  final bool writesAllowed;
  bool get isKnownV27 =>
      userVersion == 27 && identityHash == 'af22c7c534a04acc4530d670ac9e43c4';
}

class LibraryLocation {
  const LibraryLocation({required this.rootPath, required this.schema});
  final String rootPath;
  final SchemaStatus schema;
}

class ArticleHistory {
  const ArticleHistory({required this.createdAt, required this.content});
  final DateTime createdAt;
  final String content;
}

class DailyWriting {
  const DailyWriting({
    required this.day,
    required this.articleId,
    required this.wordCount,
    required this.updatedAt,
  });
  final DateTime day;
  final String articleId;
  final int wordCount;
  final DateTime updatedAt;
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

  WritingArticle copyWith({String? content}) => WritingArticle(
    id: id,
    title: title,
    content: content ?? this.content,
    summary: summary,
    folderId: folderId,
    categoryId: categoryId,
    updatedAt: updatedAt,
  );
}

class WritingLibrary {
  const WritingLibrary({
    required this.folders,
    required this.categories,
    required this.articles,
  });
  final List<WritingFolder> folders;
  final List<WritingCategory> categories;
  final List<ArticleSummary> articles;
}
