import '../models/ai_chat_session.dart';
import '../models/library_backup.dart';
import '../models/purewriter_models.dart';
import '../models/quick_toolbar_config.dart';

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

  /// Loads full article bodies for library search.
  ///
  /// Scope (first match wins):
  /// - [articleId] → that chapter
  /// - [folderId] + [categoryId] → volume
  /// - [folderId] + [unfiledOnly] → chapters with null category in the book
  /// - [folderId] → whole book
  /// - none → all non-deleted articles; trash excluded unless [includeTrash]
  Future<List<WritingArticle>> loadArticlesForSearch({
    String? folderId,
    String? categoryId,
    String? articleId,
    bool unfiledOnly = false,
    bool includeTrash = false,
  });
  Future<WritingArticle> createArticle({
    required String folderId,
    String? categoryId,
    String? afterArticleId,
  });
  Future<void> saveArticle(WritingArticle article);
  Future<void> renameArticle({
    required String articleId,
    required String title,
  });
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

  /// Moves a chapter into another book as unfiled (clears [categoryId]).
  Future<void> moveArticleToFolder({
    required String articleId,
    required String folderId,
  });

  /// Moves a volume and all of its chapters into another book.
  Future<void> moveCategoryToFolder({
    required String categoryId,
    required String folderId,
  });

  /// Turns a volume into a new book: creates a folder named after the volume,
  /// moves its chapters in as unfiled, and soft-deletes the volume.
  Future<WritingFolder> convertCategoryToFolder({required String categoryId});

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

  /// Creates a book (folder). [name] is trimmed; empty becomes `Untitled`.
  Future<WritingFolder> createFolder({
    required String name,
    String description = '',
    String tags = '',
  });

  /// Soft-deletes a book. Fails if it still has non-deleted articles, or if
  /// [folderId] is the trash folder.
  Future<void> deleteFolder(String folderId);

  /// Rewrites [rank] for every non-trash book to match [orderedIds].
  /// Trash is always kept after the listed books.
  Future<void> reorderFolders({required List<String> orderedIds});

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
  /// Returns merge chapter stats when [mode] is [RestoreMode.merge].
  Future<LibraryMergeStats> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  });
  Future<void> pruneBackups({int keep = 25});

  /// Stable id for cloud sync folders, stored in ZephyrMeta (created once).
  Future<String> ensureCloudLibraryId();

  /// True when any non-deleted article has non-empty body text.
  Future<bool> hasArticleContent();

  /// Overwrite [ensureCloudLibraryId] (e.g. empty library claiming a cloud id).
  Future<void> setCloudLibraryId(String id);

  /// IME quick-toolbar layout for this library (`null` when never saved).
  Future<QuickToolbarConfig?> readQuickToolbarConfig();

  /// Persists toolbar layout into ZephyrMeta (included in `.pwb` backups).
  Future<void> writeQuickToolbarConfig(QuickToolbarConfig config);

  // --- AI chat sessions (Zephyr-only tables in Room.db) ---

  Future<List<AiChatSession>> listAiChatSessions(
    String articleId, {
    bool includeArchived = false,
  });

  /// Last active session for this chapter when it has at least one stored message.
  Future<AiChatSession?> loadActiveAiChatSession(String articleId);

  /// Clears the active session pointer; does not create a DB session until send.
  Future<void> beginNewAiChatConversation(String articleId);

  Future<AiChatSession?> getAiChatSession(String sessionId);

  Future<AiChatSession> createAiChatSession({
    required String articleId,
    String? title,
  });

  Future<void> setActiveAiChatSession({
    required String articleId,
    required String sessionId,
  });

  Future<void> renameAiChatSession({
    required String sessionId,
    required String title,
  });

  Future<void> archiveAiChatSession(String sessionId, {required bool archived});

  Future<void> deleteAiChatSession(String sessionId);

  Future<List<AiChatStoredMessage>> listAiChatMessages(String sessionId);

  Future<AiChatStoredMessage> appendAiChatMessage({
    required String sessionId,
    required AiChatMessageRole role,
    required String body,
    String thinking = '',
    String modelBody = '',
  });

  Future<void> updateAiChatMessage({
    required String messageId,
    required String body,
    String thinking = '',
  });

  Future<void> updateAiChatSessionSummary({
    required String sessionId,
    required String contextSummary,
  });

  Future<void> pruneAiChatMessagesBefore({
    required String sessionId,
    required int keepFromSortOrder,
  });

  /// Restores list scroll for a chapter session ([sessionId] when set).
  Future<double?> loadAiChatScrollOffset({
    required String articleId,
    String? sessionId,
  });

  Future<void> saveAiChatScrollOffset({
    required String articleId,
    String? sessionId,
    required double offset,
  });
}
