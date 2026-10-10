import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../domain/models/chapter_sort_mode.dart';
import '../../../../domain/models/library_backup.dart';
import '../../../../domain/models/purewriter_models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../domain/models/workspace_layout.dart';
import '../../../../domain/repositories/workspace_layout_repository.dart';
import '../../../../domain/repositories/writing_library_repository.dart';
import '../../../../domain/use_cases/article_preview_summary.dart';

/// Editor highlight requested after picking a library search match.
class SearchHighlight {
  const SearchHighlight({
    required this.articleId,
    required this.query,
    this.start,
    this.end,
  });

  final String articleId;
  final String query;

  /// UTF-16 range in stored content; null = title-only (open chapter, no hl).
  final int? start;
  final int? end;

  bool get hasContentRange =>
      start != null && end != null && start! >= 0 && end! >= start!;
}

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(
    this._repository, {
    Object? initialError,
    this._layoutRepository,
    bool needsLibrarySetup = true,
    Uuid? uuid,
  }) : _error = initialError,
       _needsLibrarySetup = needsLibrarySetup,
       _uuid = uuid ?? const Uuid();
  final WritingLibraryRepository _repository;
  final WorkspaceLayoutRepository? _layoutRepository;
  final Uuid _uuid;
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
  bool _booksSheetDualColumn = true;
  bool _booksSheetDualColumnHydrated = false;
  String? _lastLibraryRoot;
  String? _lastLibraryBookmark;
  String? _activeLibraryId;
  List<LibraryRegistryEntry> _libraries = const [];
  String? _selectedBookId;
  String? _selectedArticleId;
  final Map<String, Set<String>> _expandedVolumesByBook = {};
  final Map<String, double> _sidebarScrollOffsetByBook = {};
  final Map<String, ChapterSortMode> _chapterSortByBook = {};
  /// Snapshot of expanded volume ids while a volume drag temporarily collapses all.
  Set<String>? _volumeExpandSnapshotDuringDrag;
  SearchHighlight? _pendingSearchHighlight;
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

  /// Set by [requestSearchJump]; consumed by the workspace editor.
  SearchHighlight? get pendingSearchHighlight => _pendingSearchHighlight;

  /// True until the user has chosen a PureWriter library folder.
  bool get needsLibrarySetup => _needsLibrarySetup;
  bool get isSidebarExpanded => _isSidebarExpanded;
  /// When true, sidebar rows show immediate-drag handles for reordering.
  bool get isReorderMode => _isReorderMode;

  /// Chapter display order for the selected book (manual = DB rank).
  ChapterSortMode get chapterSortMode {
    final bookId = _selectedBookId;
    if (bookId == null) return ChapterSortMode.manual;
    return _chapterSortByBook[bookId] ?? ChapterSortMode.manual;
  }

  bool get isResizingSidebar => _isResizingSidebar;
  double get sidebarWidth => _sidebarWidth;
  /// Mobile books sheet two-column grid layout (persisted in workspace layout).
  bool get booksSheetDualColumn => _booksSheetDualColumn;
  bool get hasVolumes => _volumesForSelectedBook.isNotEmpty;
  bool get areAllVolumesExpanded =>
      hasVolumes &&
      _volumesForSelectedBook.every(
        (volume) => isVolumeExpanded(volume.id),
      );
  WritingFolder? get selectedBook =>
      _library?.folders.where((book) => book.id == _selectedBookId).firstOrNull;
  /// Registered libraries (ordered). Empty while using only the temporary library.
  List<LibraryRegistryEntry> get libraries => _libraries;

  String? get activeLibraryId => _activeLibraryId;

  LibraryRegistryEntry? get activeLibrary {
    final id = _activeLibraryId;
    if (id == null) return null;
    for (final entry in _libraries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

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
    final registered = activeLibrary?.displayName.trim();
    if (registered != null && registered.isNotEmpty) {
      return registered;
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

  void collapseSidebar() {
    if (!_isSidebarExpanded) return;
    _isSidebarExpanded = false;
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
    if (!chapterSortMode.isManual) {
      // Drag reorder only applies while displaying the stored manual order.
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
    final next = value &&
        !isReadOnly &&
        selectedBook?.isTrash != true &&
        chapterSortMode.isManual;
    if (_isReorderMode == next) return;
    if (!next) {
      endVolumeReorderDrag();
    }
    _isReorderMode = next;
    notifyListeners();
  }

  void setChapterSortMode(ChapterSortMode mode) {
    final bookId = _selectedBookId;
    if (bookId == null || selectedBook?.isTrash == true) return;
    final current = _chapterSortByBook[bookId] ?? ChapterSortMode.manual;
    if (current == mode) return;
    if (mode.isManual) {
      _chapterSortByBook.remove(bookId);
    } else {
      _chapterSortByBook[bookId] = mode;
      if (_isReorderMode) {
        endVolumeReorderDrag();
        _isReorderMode = false;
      }
    }
    _scheduleLayoutSave();
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

  /// Expands [volumeId] if collapsed; no-op when already open.
  void ensureVolumeExpanded(String volumeId) {
    if (isVolumeExpanded(volumeId)) return;
    toggleVolume(volumeId);
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

  void setBooksSheetDualColumn(bool value) {
    if (_booksSheetDualColumn == value) return;
    _booksSheetDualColumn = value;
    _booksSheetDualColumnHydrated = true;
    _scheduleLayoutSave();
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

  Future<WritingFolder?> createBook({
    required String name,
    String description = '',
    String tags = '',
  }) async {
    if (isReadOnly) return null;
    final folder = await _repository.createFolder(
      name: name,
      description: description,
      tags: tags,
    );
    await load();
    await selectBook(folder.id);
    return folder;
  }

  /// Returns `true` when deleted. Throws [FolderNotEmptyException] when the
  /// book still has chapters.
  Future<bool> deleteBook(String folderId) async {
    if (isReadOnly || folderId == WritingFolder.trashId) return false;
    await _repository.deleteFolder(folderId);
    if (_selectedBookId == folderId) {
      _selectedBookId = null;
      _selectedArticleId = null;
      _article = null;
    }
    await load();
    return true;
  }

  Future<void> reorderBooks(List<String> orderedIds) async {
    if (isReadOnly) return;
    await _repository.reorderFolders(orderedIds: orderedIds);
    await load();
  }

  bool isBookEmpty(String bookId) => bookStats(bookId).chapters == 0;

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

  /// Opens [rootPath], registering it in the library list when new.
  Future<void> openLibrary(String rootPath, {String? bookmark}) =>
      addLibrary(rootPath, bookmark: bookmark);

  /// Adds or activates a library at [rootPath] and opens it.
  Future<void> addLibrary(
    String rootPath, {
    String? bookmark,
    String? displayName,
  }) async {
    try {
      await flushPending();
      await _repository.openLibrary(rootPath);
      final opened = _repository.location?.rootPath ?? rootPath;
      _registerOrActivate(
        rootPath: opened,
        bookmark: bookmark,
        displayName: displayName,
      );
      _needsLibrarySetup = false;
      _resetBookUiState();
      await _saveLayout();
      await load();
    } on Object catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  Future<void> switchLibrary(String id) async {
    final entry = _libraries.where((item) => item.id == id).firstOrNull;
    if (entry == null) return;
    if (entry.id == _activeLibraryId &&
        _repository.location?.rootPath == entry.rootPath) {
      return;
    }
    try {
      await flushPending();
      await _repository.openLibrary(entry.rootPath);
      _activeLibraryId = entry.id;
      _lastLibraryRoot = _repository.location?.rootPath ?? entry.rootPath;
      _lastLibraryBookmark = entry.bookmark;
      _needsLibrarySetup = false;
      _resetBookUiState();
      await _saveLayout();
      await load();
    } on Object catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  Future<void> renameLibrary(String id, String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    final index = _libraries.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final next = List<LibraryRegistryEntry>.from(_libraries);
    next[index] = next[index].copyWith(displayName: trimmed);
    _libraries = List<LibraryRegistryEntry>.unmodifiable(next);
    await _saveLayout();
    notifyListeners();
  }

  /// Removes [id] from the registry only (does not delete files on disk).
  Future<void> removeLibrary(String id) async {
    final index = _libraries.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final removedActive = _activeLibraryId == id;
    final next = List<LibraryRegistryEntry>.from(_libraries)..removeAt(index);
    for (var i = 0; i < next.length; i++) {
      next[i] = next[i].copyWith(rank: i);
    }
    _libraries = List<LibraryRegistryEntry>.unmodifiable(next);

    if (!removedActive) {
      await _saveLayout();
      notifyListeners();
      return;
    }

    if (_libraries.isEmpty) {
      try {
        await flushPending();
        await _repository.openDefaultLibrary();
        _activeLibraryId = null;
        _lastLibraryRoot = null;
        _lastLibraryBookmark = null;
        _needsLibrarySetup = true;
        _resetBookUiState();
        await _saveLayout();
        await load();
      } on Object catch (error) {
        _error = error;
        notifyListeners();
      }
      return;
    }

    final fallback = _libraries[index.clamp(0, _libraries.length - 1)];
    await switchLibrary(fallback.id);
  }

  void _registerOrActivate({
    required String rootPath,
    String? bookmark,
    String? displayName,
  }) {
    final existingIndex = _libraries.indexWhere(
      (entry) => _sameLibraryPath(entry.rootPath, rootPath),
    );
    if (existingIndex >= 0) {
      final existing = _libraries[existingIndex];
      final next = List<LibraryRegistryEntry>.from(_libraries);
      next[existingIndex] = existing.copyWith(
        rootPath: rootPath,
        bookmark: bookmark ?? existing.bookmark,
        displayName: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : existing.displayName,
      );
      _libraries = List<LibraryRegistryEntry>.unmodifiable(next);
      _activeLibraryId = existing.id;
      _lastLibraryRoot = rootPath;
      _lastLibraryBookmark = next[existingIndex].bookmark;
      return;
    }

    final entry = LibraryRegistryEntry(
      id: _uuid.v4(),
      displayName: (displayName?.trim().isNotEmpty == true)
          ? displayName!.trim()
          : path.basename(rootPath),
      rootPath: rootPath,
      bookmark: bookmark,
      rank: _libraries.length,
    );
    _libraries = List<LibraryRegistryEntry>.unmodifiable([
      ..._libraries,
      entry,
    ]);
    _activeLibraryId = entry.id;
    _lastLibraryRoot = rootPath;
    _lastLibraryBookmark = bookmark;
  }

  void _resetBookUiState() {
    _expandedVolumesByBook.clear();
    _sidebarScrollOffsetByBook.clear();
    _chapterSortByBook.clear();
    _selectedBookId = null;
    _selectedArticleId = null;
  }

  bool _sameLibraryPath(String a, String b) =>
      path.normalize(a) == path.normalize(b);

  Future<void> load() async {
    try {
      await flushPending();
      await _loadLayout();
      if (_activeLibraryId != null || _lastLibraryRoot != null) {
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

  /// Loads article bodies for search, overlaying the open dirty chapter.
  Future<List<WritingArticle>> loadArticlesForSearch({
    String? folderId,
    String? categoryId,
    String? articleId,
    bool unfiledOnly = false,
    bool includeTrash = false,
  }) async {
    final articles = await _repository.loadArticlesForSearch(
      folderId: folderId,
      categoryId: categoryId,
      articleId: articleId,
      unfiledOnly: unfiledOnly,
      includeTrash: includeTrash,
    );
    final open = _article;
    if (open == null) return articles;
    return [
      for (final article in articles)
        if (article.id == open.id) open else article,
    ];
  }

  /// Opens [articleId] and asks the editor to highlight the match.
  Future<void> requestSearchJump({
    required String articleId,
    required String query,
    int? contentStart,
    int? contentEnd,
  }) async {
    _pendingSearchHighlight = SearchHighlight(
      articleId: articleId,
      query: query,
      start: contentStart,
      end: contentEnd,
    );
    if (_article?.id != articleId) {
      await selectArticle(articleId);
    } else {
      notifyListeners();
    }
  }

  void clearSearchHighlight() {
    if (_pendingSearchHighlight == null) return;
    _pendingSearchHighlight = null;
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

  /// Persists any pending content/title/layout immediately.
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

    // Flush a pending layout write so last book/article survive pause/dispose.
    // Skip when nothing is queued — [load] also calls this and must not
    // overwrite disk with a still-null cold-start selection.
    if (_pendingLayoutSave != null) {
      await _flushLayout();
    }
  }

  Future<void> _flushLayout() async {
    _pendingLayoutSave?.cancel();
    _pendingLayoutSave = null;
    await _saveLayout();
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
    final previousBookId = _selectedBookId;
    if (_selectedBookId == null || !bookIds.contains(_selectedBookId)) {
      _selectedBookId =
          books.where((book) => !book.isTrash).firstOrNull?.id ??
          books.firstOrNull?.id;
    }
    // Drop expand/scroll entries for books that no longer exist.
    _expandedVolumesByBook.removeWhere((id, _) => !bookIds.contains(id));
    _sidebarScrollOffsetByBook.removeWhere((id, _) => !bookIds.contains(id));
    if (_selectedBookId != previousBookId) {
      _scheduleLayoutSave();
    }
  }

  Future<void> _restoreArticle() async {
    final library = _library;
    if (library == null) {
      _article = null;
      return;
    }

    ArticleSummary? chosen;
    // Prefer the remembered article across the whole library so a stale or
    // missing book id cannot drop the user onto another book's first chapter.
    if (_selectedArticleId != null) {
      chosen = library.articles
          .where((chapter) => chapter.id == _selectedArticleId)
          .firstOrNull;
    }
    if (chosen == null) {
      final bookId = _selectedBookId;
      if (bookId != null) {
        chosen = library.articles
            .where((chapter) => chapter.folderId == bookId)
            .firstOrNull;
      }
    }
    chosen ??= library.articles
        .where((chapter) => chapter.folderId != WritingFolder.trashId)
        .firstOrNull;

    _selectedArticleId = chosen?.id;
    if (chosen != null) {
      _selectedBookId = chosen.folderId;
    }
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
      _activeLibraryId = layout.activeLibraryId;
      _libraries = layout.libraries;
      // Keep an in-session selection across library refreshes (e.g. reorder).
      // Disk may still be null/stale when selection was only restored in memory.
      _selectedBookId ??= layout.selectedBookId;
      _selectedArticleId ??= layout.selectedArticleId;
      // Dual-column is toggled in-session; don't clobber before disk save lands.
      if (!_booksSheetDualColumnHydrated) {
        _booksSheetDualColumn = layout.booksSheetDualColumn;
        _booksSheetDualColumnHydrated = true;
      }
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
      _chapterSortByBook
        ..clear()
        ..addAll({
          for (final entry in layout.chapterSortByBook.entries)
            entry.key: ChapterSortMode.fromStorageId(entry.value),
        });
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
          activeLibraryId: _activeLibraryId,
          libraries: _libraries,
          selectedBookId: _selectedBookId,
          selectedArticleId: _selectedArticleId,
          expandedVolumesByBook: {
            for (final entry in _expandedVolumesByBook.entries)
              entry.key: entry.value.toList(growable: false),
          },
          sidebarScrollOffsetByBook: Map<String, double>.from(
            _sidebarScrollOffsetByBook,
          ),
          chapterSortByBook: {
            for (final entry in _chapterSortByBook.entries)
              if (!entry.value.isManual) entry.key: entry.value.storageId,
          },
          booksSheetDualColumn: _booksSheetDualColumn,
        ),
      );
    } on Object {
      // The in-memory width remains usable if layout storage is unavailable.
    }
  }

  @override
  void dispose() {
    unawaited(flushPending());
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
