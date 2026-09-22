import '../models/purewriter_models.dart';

/// PureWriter-compatible library operations. The Room database remains the
/// source of truth; UI never talks to SQLite directly.
abstract interface class WritingLibraryRepository {
  Future<WritingLibrary> loadLibrary();
  Future<WritingArticle> getArticle(String id);
  Future<WritingArticle> createArticle({required String folderId});
  Future<void> saveArticle(WritingArticle article);
}
