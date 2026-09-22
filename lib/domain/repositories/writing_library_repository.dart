import '../models/purewriter_models.dart';

/// PureWriter-compatible library operations. The Room database remains the
/// source of truth; UI never talks to SQLite directly.
abstract interface class WritingLibraryRepository {
  Future<LibraryLocation> openLibrary(String rootPath);
  Future<void> closeLibrary();
  LibraryLocation? get location;
  Future<WritingLibrary> loadLibrary();
  Future<WritingArticle> getArticle(String id);
  Future<WritingArticle> createArticle({required String folderId});
  Future<void> saveArticle(WritingArticle article);
  Future<WritingCategory> createCategory({
    required String folderId,
    required String name,
  });
  Future<void> trashArticle(String articleId);
  Future<void> restoreArticle(String articleId, {required String folderId});
  Future<List<ArticleHistory>> listHistory(String articleId);
  Future<List<DailyWriting>> listDaily();
  Future<Map<String, double>> readScrolls();
  Future<void> writeScroll(String articleId, double offset);
}
