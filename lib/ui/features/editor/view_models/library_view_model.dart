import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../../../domain/models/purewriter_models.dart';
import '../../../../domain/models/workspace_layout.dart';
import '../../../../domain/repositories/workspace_layout_repository.dart';
import '../../../../domain/repositories/writing_library_repository.dart';

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
  String get libraryName {
    if (needsLibrarySetup) {
      return '临时书库';
    }
    final name = path.basename(_repository.location?.rootPath ?? '');
    return name.isEmpty ? 'Untitled library' : name;
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
      _error = null;
    } on Object catch (error) {
      _error = error;
    }
    notifyListeners();
  }

  Future<void> selectArticle(String id) async {
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
    _article = WritingArticle(
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
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 500), save);
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
    _pendingTitleSave?.cancel();
    _pendingTitleSave = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persistTitle(article.id, title));
    });
    notifyListeners();
  }

  Future<void> _persistTitle(String articleId, String title) async {
    try {
      await _repository.renameArticle(articleId: articleId, title: title);
    } on Object {
      // Keep the in-memory title; the next edit retries persistence.
    }
  }

  Future<void> save() async {
    _pendingSave?.cancel();
    final article = _article;
    if (article != null) await _repository.saveArticle(article);
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
    _pendingSave?.cancel();
    if (_pendingTitleSave?.isActive == true) {
      _pendingTitleSave?.cancel();
      final article = _article;
      if (article != null) {
        unawaited(_persistTitle(article.id, article.title));
      }
    } else {
      _pendingTitleSave?.cancel();
    }
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
