import '../models/library_backup.dart';
import '../models/purewriter_models.dart';

/// PureWriter-compatible library operations. The Room database remains the
/// source of truth; UI never talks to SQLite directly.
abstract interface class WritingLibraryRepository {
  Future<LibraryLocation> openLibrary(String rootPath);

  /// Opens the app-support temporary library, creating it when missing.
  Future<LibraryLocation> openDefaultLibrary();
  Future<void> closeLibrary();
  LibraryLocation? get location;
  Future<WritingLibrary> loadLibrary();
  Future<WritingArticle> getArticle(String id);
  Future<WritingArticle> createArticle({
    required String folderId,
    String? categoryId,
    String? afterArticleId,
  });
  Future<void> saveArticle(WritingArticle article);
  Future<void> renameArticle({required String articleId, required String title});
  Future<WritingCategory> createCategory({
    required String folderId,
    required String name,
    String? afterCategoryId,
  });
  Future<void> renameCategory({
    required String categoryId,
    required String name,
  });
  Future<void> deleteCategory({
    required String categoryId,
    required bool deleteArticles,
  });
  Future<void> moveArticleToCategory({
    required String articleId,
    String? categoryId,
  });
  Future<void> reorderCategories({
    required String folderId,
    required List<String> orderedIds,
  });
  Future<void> reorderArticles({
    required String folderId,
    String? categoryId,
    required List<String> orderedIds,
  });
  Future<void> updateFolder({
    required String folderId,
    required String name,
    String? description,
    String? tags,
  });
  Future<void> trashArticle(String articleId);
  Future<void> restoreArticle(String articleId, {required String folderId});
  Future<List<ArticleHistory>> listHistory(String articleId);
  Future<void> restoreHistory({
    required String articleId,
    required DateTime createdAt,
  });
  Future<List<DailyWriting>> listDaily();
  Future<Map<String, double>> readScrolls();
  Future<void> writeScroll(String articleId, double offset);

  /// Upserts a Zephyr-only crash draft (does not change Article).
  Future<void> upsertDraft(ArticleDraft draft);
  Future<void> clearDraft(String articleId);
  Future<ArticleDraft?> getDraft(String articleId);
  Future<List<ArticleDraft>> listDraftsNewerThanArticles();

  Future<List<BackupEntry>> listBackups();
  Future<BackupEntry> createBackup({required BackupKind kind});
  Future<void> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  });
  Future<void> pruneAutomaticBackups({int keep = 25});
}
