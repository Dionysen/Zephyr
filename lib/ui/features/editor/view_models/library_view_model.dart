import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../../../domain/models/library_backup.dart';
import '../../../../domain/models/purewriter_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/models/workspace_layout.dart';
import '../../../../domain/repositories/workspace_layout_repository.dart';
import '../../../../domain/repositories/writing_library_repository.dart';
import '../../../../domain/use_cases/article_preview_summary.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(
    this._repository, {
    Object? initialError,
    this._layoutRepository,
    bool needsLibrarySetup = true,
  }) : _error = initialError,
       _needsLibrarySetup = needsLibrarySetup;
  final WritingLibraryRepository _repository;
  final WorkspaceLayoutRepository? _layoutRepository;
  WritingLibrary? _library;
  WritingArticle? _article;
  Object? _error;
  bool _needsLibrarySetup;
  Timer? _pendingSave;
  Timer? _pendingTitleSave;
  Timer? _pendingLayoutSave;
  Timer? _pendingDraftSave;
  /// Content/title awaiting persistence, keyed by article id (survives chapter switch).
  WritingArticle? _dirtyArticle;
  String? _dirtyTitleArticleId;
  String? _dirtyTitle;
  List<ArticleDraft> _recoverableDrafts = const [];
  var _contentDirtySinceBackup = false;
  bool _isSidebarExpanded = true;
  bool _isReorderMode = false;
  bool _isResizingSidebar = false;
  double _sidebarWidth = WorkspaceLayout.defaults.sidebarWidth;
  String? _lastLibraryRoot;
  String? _lastLibraryBookmark;
  String? _selectedBookId;
  String? _selectedArticleId;
  final Map<String, Set<String>> _expandedVolumesByBook = {};
  final Map<String, double> _sidebarScrollOffsetByBook = {};
  /// Snapshot of expanded volume ids while a volume drag temporarily collapses all.
  Set<String>? _volumeExpandSnapshotDuringDrag;
  static const minSidebarWidth = WorkspaceLayout.minSidebarWidth;
  static const maxSidebarWidth = WorkspaceLayout.maxSidebarWidth;
  static const defaultSidebarWidth = WorkspaceLayout.defaultSidebarWidth;
  WritingLibrary? get library => _library;
  WritingArticle? get article => _article;
  Object? get error => _error;
  bool get isLibraryInUse => _error is LibraryInUseException;
  bool get isReadOnly => _repository.location?.schema.writesAllowed == false;
  /// Drafts newer than Article after load — UI may offer recovery.
  List<ArticleDraft> get recoverableDrafts => _recoverableDrafts;
  bool get contentDirtySinceBackup => _contentDirtySinceBackup;
  WritingLibraryRepository get repository => _repository;
  /// True until the user has chosen a PureWriter library folder.
  bool get needsLibrarySetup => _needsLibrarySetup;
  bool get isSidebarExpanded => _isSidebarExpanded;
  /// When true, sidebar rows show immediate-drag handles for reordering.
  bool get isReorderMode => _isReorderMode;
  bool get isResizingSidebar => _isResizingSidebar;
  double get sidebarWidth => _sidebarWidth;
  bool get hasVolumes => _volumesForSelectedBook.isNotEmpty;
  bool get areAllVolumesExpanded =>
      hasVolumes &&
      _volumesForSelectedBook.every(
        (volume) => isVolumeExpanded(volume.id),
      );
  WritingFolder? get selectedBook =>
      _library?.folders.where((book) => book.id == _selectedBookId).firstOrNull;
  /// Folder basename for the open library, or empty while using a temp library.
  String get libraryName {
    if (needsLibrarySetup) {
      return '';
    }
    return path.basename(_repository.location?.rootPath ?? '');
  }

  String displayLibraryName(AppLocalizations l10n) {
    if (needsLibrarySetup) {
      return l10n.temporaryLibraryName;
    }
    final name = libraryName;
    return name.isEmpty ? l10n.untitledLibrary : name;
  }

  double get sidebarScrollOffset {
    final bookId = _selectedBookId;
    if (bookId == null) return 0;
    return _sidebarScrollOffsetByBook[bookId] ?? 0;
  }

  bool isVolumeExpanded(String volumeId) {
    final bookId = _selectedBookId;
    if (bookId == null) return true;
    final set = _expandedVolumesByBook[bookId];
    if (set == null) return true;
    return set.contains(volumeId);
  }

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }

  void toggleReorderMode() {
    if (isReadOnly || selectedBook?.isTrash == true) {
      if (!_isReorderMode) return;
      endVolumeReorderDrag();
      _isReorderMode = false;
      notifyListeners();
      return;
    }
    if (_isReorderMode) {
      endVolumeReorderDrag();
    }
    _isReorderMode = !_isReorderMode;
    notifyListeners();
  }

  void setReorderMode(bool value) {
    final next = value && !isReadOnly && selectedBook?.isTrash != true;
    if (_isReorderMode == next) return;
    if (!next) {
      endVolumeReorderDrag();
    }
    _isReorderMode = next;
    notifyListeners();
  }

  /// Collapse every volume for the duration of a volume-row drag.
  ///
  /// Does not persist layout; [endVolumeReorderDrag] restores the prior set.
  void beginVolumeReorderDrag() {
    final bookId = _selectedBookId;
    if (bookId == null || !hasVolumes) return;
    if (_volumeExpandSnapshotDuringDrag != null) return;
    final current = _expandedVolumesByBook[bookId];
    _volumeExpandSnapshotDuringDrag = current == null
        ? _volumesForSelectedBook.map((volume) => volume.id).toSet()
        : Set<String>.from(current);
    _expandedVolumesByBook[bookId] = <String>{};
    notifyListeners();
  }

  void endVolumeReorderDrag() {
    final snapshot = _volumeExpandSnapshotDuringDrag;
    if (snapshot == null) return;
    _volumeExpandSnapshotDuringDrag = null;
    final bookId = _selectedBookId;
    if (bookId != null) {
      _expandedVolumesByBook[bookId] = snapshot;
    }
    notifyListeners();
  }

  void toggleVolume(String volumeId) {
    final bookId = _selectedBookId;
    if (bookId == null) return;
    final set = _expandedVolumesByBook.putIfAbsent(
      bookId,
      () => _volumesForSelectedBook.map((volume) => volume.id).toSet(),
    );
    if (!set.add(volumeId)) {
      set.remove(volumeId);
    }
    _scheduleLayoutSave();
    notifyListeners();
  }

  void toggleAllVolumes() {
    if (!hasVolumes) return;
    final bookId = _selectedBookId;
    if (bookId == null) return;
    if (areAllVolumesExpanded) {
      _expandedVolumesByBook[bookId] = <String>{};
    } else {
      _expandedVolumesByBook[bookId] =
          _volumesForSelectedBook.map((volume) => volume.id).toSet();
    }
    _scheduleLayoutSave();
    notifyListeners();
  }

  void updateSidebarScrollOffset(double offset) {
    final bookId = _selectedBookId;
    if (bookId == null) return;
    final clamped = offset < 0 ? 0.0 : offset;
    if ((_sidebarScrollOffsetByBook[bookId] ?? 0) == clamped) return;
    _sidebarScrollOffsetByBook[bookId] = clamped;
    _scheduleLayoutSave();
  }

  void resizeSidebar(double width) {
    final next = WorkspaceLayout.clamped(width).sidebarWidth;
    if (next == _sidebarWidth) return;
    _sidebarWidth = next;
    if (!_isResizingSidebar) {
      _scheduleLayoutSave();
    }
    notifyListeners();
  }

  void setSidebarResizing(bool value) {
    if (_isResizingSidebar == value) return;
    _isResizingSidebar = value;
    if (!value) {
      _scheduleLayoutSave();
    }
    notifyListeners();
  }

  Future<void> selectBook(String bookId) async {
    if (_selectedBookId == bookId) return;
    await flushPending();
    if (bookId == WritingFolder.trashId) {
      _isReorderMode = false;
    }
    _selectedBookId = bookId;
    final chapters = _chaptersForSelectedBook;
    final preferredId = _selectedArticleId;
    final preferred = preferredId == null
        ? null
        : chapters.where((chapter) => chapter.id == preferredId).firstOrNull;
    final chapter = preferred ?? chapters.firstOrNull;
    _selectedArticleId = chapter?.id;
    _article = chapter == null
        ? null
        : await _repository.getArticle(chapter.id);
    _scheduleLayoutSave();
    notifyListeners();
  }

  Future<void> updateBook({
    required String folderId,
    required String name,
    String? description,
    String? tags,
  }) async {
    if (isReadOnly) return;
    await _repository.updateFolder(
      folderId: folderId,
      name: name,
      description: description,
      tags: tags,
    );
    await load();
  }

  ({int volumes, int chapters}) bookStats(String bookId) {
    final library = _library;
    if (library == null) {
      return (volumes: 0, chapters: 0);
    }
    return (
      volumes: library.categories.where((item) => item.folderId == bookId).length,
      chapters: library.articles.where((item) => item.folderId == bookId).length,
    );
  }

  Future<void> openLibrary(String rootPath, {String? bookmark}) async {
    try {
      await flushPending();
      await _repository.openLibrary(rootPath);
      _lastLibraryRoot = _repository.location?.rootPath ?? rootPath;
      _needsLibrarySetup = false;
      if (bookmark != null) {
        _lastLibraryBookmark = bookmark;
      }
      _expandedVolumesByBook.clear();
      _sidebarScrollOffsetByBook.clear();
      _selectedBookId = null;
      _selectedArticleId = null;
      await _saveLayout();
      await load();
    } on Object catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  Future<void> load() async {
    try {
      await flushPending();
      await _loadLayout();
      if (_lastLibraryRoot != null) {
        _needsLibrarySetup = false;
      } else if (_layoutRepository != null) {
        // A persisted layout with no chosen folder means temporary-library mode.
        _needsLibrarySetup = true;
      }
      if (_repository.location == null) {
        await _repository.openDefaultLibrary();
      }
      _library = await _repository.loadLibrary();
      _restoreSelection();
      await _restoreArticle();
      _recoverableDrafts = await _repository.listDraftsNewerThanArticles();
      _error = null;
    } on Object catch (error) {
      _error = error;
    }
    notifyListeners();
  }

  Future<void> selectArticle(String id) async {
    await flushPending();
    _article = await _repository.getArticle(id);
    _selectedArticleId = _article?.id;
    if (_article != null) {
      _selectedBookId = _article!.folderId;
    }
    _scheduleLayoutSave();
    notifyListeners();
  }

  Future<void> createArticle() async {
    if (isReadOnly) return;
    await flushPending();
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    _article = await _repository.createArticle(folderId: book.id);
    _selectedArticleId = _article?.id;
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> createVolume({String name = 'Untitled'}) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    final volume = await _repository.createCategory(
      folderId: book.id,
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
    );
    final expanded = _expandedVolumesByBook[book.id];
    if (expanded != null) {
      expanded.add(volume.id);
    }
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> insertVolumeBelow(String afterVolumeId) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    final volume = await _repository.createCategory(
      folderId: book.id,
      name: 'Untitled',
      afterCategoryId: afterVolumeId,
    );
    final expanded = _expandedVolumesByBook[book.id];
    if (expanded != null) {
      expanded.add(volume.id);
    }
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> insertChapterBelow(String afterArticleId) async {
    if (isReadOnly) return;
    await flushPending();
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    final after = _library?.articles
        .where((chapter) => chapter.id == afterArticleId)
        .firstOrNull;
    if (after == null || after.folderId != book.id) return;
    _article = await _repository.createArticle(
      folderId: book.id,
      categoryId: after.categoryId,
      afterArticleId: afterArticleId,
    );
    _selectedArticleId = _article?.id;
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> renameVolume({
    required String volumeId,
    required String name,
  }) async {
    if (isReadOnly) return;
    await _repository.renameCategory(categoryId: volumeId, name: name);
    await load();
    notifyListeners();
  }

  Future<void> renameChapter({
    required String articleId,
    required String title,
  }) async {
    if (isReadOnly) return;
    await _repository.renameArticle(articleId: articleId, title: title);
    if (_article?.id == articleId) {
      _article = await _repository.getArticle(articleId);
    }
    await load();
    notifyListeners();
  }

  Future<void> deleteVolume({
    required String volumeId,
    required bool deleteArticles,
  }) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    final removedIds = _library?.articles
            .where((chapter) => chapter.categoryId == volumeId)
            .map((chapter) => chapter.id)
            .toSet() ??
        const <String>{};
    await _repository.deleteCategory(
      categoryId: volumeId,
      deleteArticles: deleteArticles,
    );
    _expandedVolumesByBook[book.id]?.remove(volumeId);
    if (deleteArticles &&
        _selectedArticleId != null &&
        removedIds.contains(_selectedArticleId)) {
      _selectedArticleId = null;
      _article = null;
    }
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> deleteChapter(String articleId) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    await _repository.trashArticle(articleId);
    if (_selectedArticleId == articleId) {
      _selectedArticleId = null;
      _article = null;
    }
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> moveChapterToVolume({
    required String articleId,
    String? volumeId,
  }) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    await _repository.moveArticleToCategory(
      articleId: articleId,
      categoryId: volumeId,
    );
    if (volumeId != null) {
      final expanded = _expandedVolumesByBook[book.id];
      if (expanded != null) {
        expanded.add(volumeId);
      }
    }
    if (_article?.id == articleId) {
      _article = await _repository.getArticle(articleId);
    }
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  Future<void> reorderVolumes(List<String> orderedIds) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    await _repository.reorderCategories(
      folderId: book.id,
      orderedIds: orderedIds,
    );
    await load();
    notifyListeners();
  }

  Future<void> reorderChapters({
    String? volumeId,
    required List<String> orderedIds,
  }) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    await _repository.reorderArticles(
      folderId: book.id,
      categoryId: volumeId,
      orderedIds: orderedIds,
    );
    await load();
    notifyListeners();
  }

  void updateContent(String content) {
    final article = _article;
    if (article == null) return;
    final next = WritingArticle(
      id: article.id,
      title: article.title,
      content: content,
      summary: article.summary,
      folderId: article.folderId,
      categoryId: article.categoryId,
      createdAt: article.createdAt,
      updatedAt: DateTime.now(),
      wordCount: content.runes.where((rune) => rune != 10 && rune != 13).length,
    );
    _article = next;
    _dirtyArticle = next;
    _contentDirtySinceBackup = true;
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 500), () {
      unawaited(save());
    });
    _scheduleDraftUpsert(next);
    notifyListeners();
  }

  /// Updates the open chapter title locally and persists via [renameArticle].
  ///
  /// [saveArticle] only writes content, so title changes cannot share that path.
  void updateTitle(String title) {
    if (isReadOnly) return;
    final article = _article;
    if (article == null) return;
    _article = WritingArticle(
      id: article.id,
      title: title,
      content: article.content,
      summary: article.summary,
      folderId: article.folderId,
      categoryId: article.categoryId,
      createdAt: article.createdAt,
      updatedAt: DateTime.now(),
      wordCount: article.wordCount,
    );
    final library = _library;
    if (library != null) {
      _library = WritingLibrary(
        folders: library.folders,
        categories: library.categories,
        articles: [
          for (final chapter in library.articles)
            if (chapter.id == article.id)
              ArticleSummary(
                id: chapter.id,
                title: title,
                summary: chapter.summary,
                folderId: chapter.folderId,
                categoryId: chapter.categoryId,
                createdAt: chapter.createdAt,
                updatedAt: DateTime.now(),
                wordCount: chapter.wordCount,
              )
            else
              chapter,
        ],
      );
    }
    _dirtyTitleArticleId = article.id;
    _dirtyTitle = title;
    _contentDirtySinceBackup = true;
    _pendingTitleSave?.cancel();
    _pendingTitleSave = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistTitle(article.id, title));
    });
    final draftSource = _dirtyArticle ?? _article;
    if (draftSource != null) {
      _scheduleDraftUpsert(
        WritingArticle(
          id: draftSource.id,
          title: title,
          content: draftSource.content,
          summary: draftSource.summary,
          folderId: draftSource.folderId,
          categoryId: draftSource.categoryId,
          createdAt: draftSource.createdAt,
          updatedAt: DateTime.now(),
          wordCount: draftSource.wordCount,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _persistTitle(String articleId, String title) async {
    try {
      await _repository.renameArticle(articleId: articleId, title: title);
      if (_dirtyTitleArticleId == articleId && _dirtyTitle == title) {
        _dirtyTitleArticleId = null;
        _dirtyTitle = null;
      }
    } on Object {
      // Keep the in-memory title; the next edit retries persistence.
    }
  }

  /// Persists any pending content/title immediately (by article id snapshot).
  Future<void> flushPending() async {
    _pendingSave?.cancel();
    _pendingSave = null;
    _pendingTitleSave?.cancel();
    _pendingTitleSave = null;
    _pendingDraftSave?.cancel();
    _pendingDraftSave = null;

    final dirty = _dirtyArticle;
    if (dirty != null) {
      _dirtyArticle = null;
      try {
        await _repository.saveArticle(dirty);
        if (_article?.id == dirty.id) {
          _refreshSidebarPreviewIfNeeded(dirty);
        }
      } on Object {
        _dirtyArticle = dirty;
        rethrow;
      }
    }

    final titleId = _dirtyTitleArticleId;
    final title = _dirtyTitle;
    if (titleId != null && title != null) {
      await _persistTitle(titleId, title);
    }
  }

  Future<void> save() async {
    _pendingSave?.cancel();
    final article = _dirtyArticle ?? _article;
    if (article == null) return;
    _dirtyArticle = null;
    await _repository.saveArticle(article);
    if (_article?.id == article.id) {
      _refreshSidebarPreviewIfNeeded(article);
    }
  }

  void _scheduleDraftUpsert(WritingArticle article) {
    if (isReadOnly) return;
    _pendingDraftSave?.cancel();
    _pendingDraftSave = Timer(const Duration(milliseconds: 150), () {
      unawaited(
        _repository.upsertDraft(
          ArticleDraft(
            articleId: article.id,
            content: article.content,
            title: article.title,
            updatedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  Future<void> applyRecoverableDraft(ArticleDraft draft) async {
    await _repository.saveArticle(
      (await _repository.getArticle(draft.articleId)).copyWith(
        content: draft.content,
      ),
    );
    if (draft.title.isNotEmpty) {
      await _repository.renameArticle(
        articleId: draft.articleId,
        title: draft.title,
      );
    }
    await _repository.clearDraft(draft.articleId);
    _recoverableDrafts = [
      for (final item in _recoverableDrafts)
        if (item.articleId != draft.articleId) item,
    ];
    if (_selectedArticleId == draft.articleId || _article?.id == draft.articleId) {
      _article = await _repository.getArticle(draft.articleId);
    }
    notifyListeners();
  }

  Future<void> dismissRecoverableDraft(ArticleDraft draft) async {
    await _repository.clearDraft(draft.articleId);
    _recoverableDrafts = [
      for (final item in _recoverableDrafts)
        if (item.articleId != draft.articleId) item,
    ];
    notifyListeners();
  }

  void markBackupCompleted() {
    _contentDirtySinceBackup = false;
  }

  Future<List<ArticleHistory>> listHistory(String articleId) =>
      _repository.listHistory(articleId);

  Future<void> restoreHistoryRevision({
    required String articleId,
    required DateTime createdAt,
  }) async {
    await flushPending();
    await _repository.restoreHistory(
      articleId: articleId,
      createdAt: createdAt,
    );
    if (_article?.id == articleId) {
      _article = await _repository.getArticle(articleId);
      notifyListeners();
    }
  }

  /// When the saved content changes the leading preview text, push it into the
  /// in-memory chapter list so the sidebar updates without a full reload.
  void _refreshSidebarPreviewIfNeeded(WritingArticle article) {
    final nextSummary = articlePreviewSummary(article.content);
    final library = _library;
    if (library == null) return;

    final index = library.articles.indexWhere((item) => item.id == article.id);
    if (index < 0) return;
    final chapter = library.articles[index];
    final summaryChanged = chapter.summary != nextSummary;
    if (!summaryChanged && article.summary == nextSummary) return;

    _article = WritingArticle(
      id: article.id,
      title: article.title,
      content: article.content,
      summary: nextSummary,
      folderId: article.folderId,
      categoryId: article.categoryId,
      createdAt: article.createdAt,
      updatedAt: article.updatedAt,
      wordCount: article.wordCount,
    );
    if (summaryChanged) {
      final articles = [...library.articles];
      articles[index] = ArticleSummary(
        id: chapter.id,
        title: chapter.title,
        summary: nextSummary,
        folderId: chapter.folderId,
        categoryId: chapter.categoryId,
        createdAt: chapter.createdAt,
        updatedAt: article.updatedAt,
        wordCount: article.wordCount,
      );
      _library = WritingLibrary(
        folders: library.folders,
        categories: library.categories,
        articles: articles,
      );
      notifyListeners();
    }
  }

  void _restoreSelection() {
    final library = _library;
    if (library == null) return;
    final books = library.folders;
    final bookIds = books.map((book) => book.id).toSet();
    if (_selectedBookId == null || !bookIds.contains(_selectedBookId)) {
      _selectedBookId =
          books.where((book) => !book.isTrash).firstOrNull?.id ??
          books.firstOrNull?.id;
    }
    // Drop expand/scroll entries for books that no longer exist.
    _expandedVolumesByBook.removeWhere((id, _) => !bookIds.contains(id));
    _sidebarScrollOffsetByBook.removeWhere((id, _) => !bookIds.contains(id));
  }

  Future<void> _restoreArticle() async {
    final library = _library;
    final bookId = _selectedBookId;
    if (library == null || bookId == null) {
      _article = null;
      return;
    }
    final chapters = library.articles
        .where((chapter) => chapter.folderId == bookId)
        .toList(growable: false);
    ArticleSummary? chosen;
    if (_selectedArticleId != null) {
      chosen = chapters
          .where((chapter) => chapter.id == _selectedArticleId)
          .firstOrNull;
    }
    chosen ??= chapters.firstOrNull;
    _selectedArticleId = chosen?.id;
    _article = chosen == null
        ? null
        : await _repository.getArticle(chosen.id);
  }

  Future<void> _loadLayout() async {
    final layoutRepository = _layoutRepository;
    if (layoutRepository == null) {
      return;
    }
    try {
      final layout = await layoutRepository.load();
      _sidebarWidth = layout.sidebarWidth;
      _lastLibraryRoot = layout.lastLibraryRoot;
      _lastLibraryBookmark = layout.lastLibraryBookmark;
      _selectedBookId = layout.selectedBookId;
      _selectedArticleId = layout.selectedArticleId;
      _expandedVolumesByBook
        ..clear()
        ..addAll(
          layout.expandedVolumesByBook.map(
            (key, value) => MapEntry(key, value.toSet()),
          ),
        );
      _sidebarScrollOffsetByBook
        ..clear()
        ..addAll(layout.sidebarScrollOffsetByBook);
    } on Object {
      // Layout preferences must not block a writing session.
    }
  }

  void _scheduleLayoutSave() {
    if (_layoutRepository == null) {
      return;
    }
    _pendingLayoutSave?.cancel();
    _pendingLayoutSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_saveLayout());
    });
  }

  Future<void> _saveLayout() async {
    try {
      await _layoutRepository?.save(
        WorkspaceLayout(
          sidebarWidth: _sidebarWidth,
          lastLibraryRoot: _lastLibraryRoot,
          lastLibraryBookmark: _lastLibraryBookmark,
          selectedBookId: _selectedBookId,
          selectedArticleId: _selectedArticleId,
          expandedVolumesByBook: {
            for (final entry in _expandedVolumesByBook.entries)
              entry.key: entry.value.toList(growable: false),
          },
          sidebarScrollOffsetByBook: Map<String, double>.from(
            _sidebarScrollOffsetByBook,
          ),
        ),
      );
    } on Object {
      // The in-memory width remains usable if layout storage is unavailable.
    }
  }

  @override
  void dispose() {
    unawaited(flushPending());
    _pendingLayoutSave?.cancel();
    super.dispose();
  }

  Iterable<WritingCategory> get _volumesForSelectedBook =>
      _library?.categories.where(
        (volume) => volume.folderId == _selectedBookId,
      ) ??
      const [];
  Iterable<ArticleSummary> get _chaptersForSelectedBook =>
      _library?.articles.where(
        (chapter) => chapter.folderId == _selectedBookId,
      ) ??
      const [];
}
