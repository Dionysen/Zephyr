// Public constructor argument names intentionally differ from private fields.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../domain/models/article_editor_state.dart';
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

  /// Called after [load] succeeds (library content is available).
  Future<void> Function()? onLibraryLoaded;

  final WritingLibraryRepository _repository;
  final WorkspaceLayoutRepository? _layoutRepository;
  final Uuid _uuid;
  WritingLibrary? _library;
  WritingArticle? _article;
  Object? _error;
  bool _needsLibrarySetup;
  var _recoveredToTemporaryLibrary = false;
  Timer? _pendingSave;
  Timer? _pendingTitleSave;
  Timer? _pendingLayoutSave;
  Timer? _pendingEditorStateSave;
  Future<void> _writeTail = Future<void>.value();

  /// Content/title awaiting persistence, keyed by article id (survives chapter switch).
  WritingArticle? _dirtyArticle;
  String? _dirtyTitleArticleId;
  String? _dirtyTitle;

  /// Per-chapter scroll + caret (mirrored into Room.db `ZephyrMeta`).
  Map<String, ArticleEditorState> _articleEditorStates = {};

  final Set<String> _pendingEditorStateArticleIds = {};

  double? editorScrollOffset(String articleId) =>
      _articleEditorStates[articleId]?.scrollOffset;

  ArticleEditorState? articleEditorState(String articleId) =>
      _articleEditorStates[articleId];

  void rememberEditorScrollOffset(String articleId, double offset) {
    final existing = _articleEditorStates[articleId];
    rememberEditorPosition(
      articleId: articleId,
      scrollOffset: offset,
      selectionBase: existing?.selectionBase ?? 0,
      selectionExtent: existing?.selectionExtent ?? 0,
    );
  }

  void rememberEditorPosition({
    required String articleId,
    required double scrollOffset,
    required int selectionBase,
    required int selectionExtent,
  }) {
    if (isReadOnly) return;
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    _articleEditorStates[articleId] = ArticleEditorState(
      scrollOffset: scrollOffset,
      selectionBase: selectionBase,
      selectionExtent: selectionExtent,
      updatedAt: updatedAt,
    );
    _pendingEditorStateArticleIds.add(articleId);
    _scheduleEditorStateSave();
  }

  Object? _saveError;
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
  String? _mobileCompanionBookId;
  String? _mobileCompanionArticleId;
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
  Object? get saveError => _saveError;
  bool get isLibraryInUse => _error is LibraryInUseException;
  bool get isReadOnly => _repository.location?.schema.writesAllowed == false;

  /// Drafts newer than Article after load — UI may offer recovery.
  List<ArticleDraft> get recoverableDrafts => _recoverableDrafts;
  bool get contentDirtySinceBackup => _contentDirtySinceBackup;

  /// Fired after article content or title is successfully written to Room.db.
  ///
  /// Used to persist a durable cloud-backup-pending flag (survives process death).
  Future<void> Function()? onLocalContentPersisted;

  WritingLibraryRepository get repository => _repository;

  /// Set by [requestSearchJump]; consumed by the workspace editor.
  SearchHighlight? get pendingSearchHighlight => _pendingSearchHighlight;

  /// True until the user has chosen a PureWriter library folder.
  bool get needsLibrarySetup => _needsLibrarySetup;

  /// Set once when [load] fell back to the app-support temporary library.
  bool get recoveredToTemporaryLibrary => _recoveredToTemporaryLibrary;

  void clearRecoveredToTemporaryLibraryNotice() {
    _recoveredToTemporaryLibrary = false;
  }

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
      _volumesForSelectedBook.every((volume) => isVolumeExpanded(volume.id));
  WritingFolder? get selectedBook =>
      _library?.folders.where((book) => book.id == _selectedBookId).firstOrNull;

  /// Compact workspace's independently selected right-hand book/editor.
  String? get mobileCompanionBookId => _mobileCompanionBookId;
  String? get mobileCompanionArticleId => _mobileCompanionArticleId;

  /// Registered by the compact two-editor host so app-level flush and backup
  /// paths include edits made in the companion editor.
  Future<void> Function()? flushMobileCompanion;

  /// Clears the companion session's dirty flag after a shared backup.
  VoidCallback? markMobileCompanionBackupCompleted;

  /// Persists the compact companion selection alongside the primary editor.
  void setMobileCompanionSelection({
    required String? bookId,
    required String? articleId,
  }) {
    if (_mobileCompanionBookId == bookId &&
        _mobileCompanionArticleId == articleId) {
      return;
    }
    _mobileCompanionBookId = bookId;
    _mobileCompanionArticleId = articleId;
    _scheduleLayoutSave();
  }

  /// Makes writes from the compact companion participate in the application's
  /// normal leave/backup dirty gate.
  void markContentDirtyFromCompanion() {
    if (_contentDirtySinceBackup) return;
    _contentDirtySinceBackup = true;
    notifyListeners();
  }

  /// The selected directory, or empty while using the temporary library.
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
    final next =
        value &&
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
      _expandedVolumesByBook[bookId] = _volumesForSelectedBook
          .map((volume) => volume.id)
          .toSet();
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
      volumes: library.categories
          .where((item) => item.folderId == bookId)
          .length,
      chapters: library.articles
          .where((item) => item.folderId == bookId)
          .length,
    );
  }

  /// Opens [rootPath] as the sole selected library directory.
  Future<void> openLibrary(String rootPath, {String? bookmark}) async {
    try {
      await flushPending();
      await _repository.openLibrary(rootPath);
      final opened = _repository.location?.rootPath ?? rootPath;
      _registerOrActivate(rootPath: opened, bookmark: bookmark);
      _needsLibrarySetup = false;
      _resetBookUiState();
      await _saveLayout();
      await load();
    } on Object catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  void _registerOrActivate({required String rootPath, String? bookmark}) {
    final existingIndex = _libraries.indexWhere(
      (entry) => _sameLibraryPath(entry.rootPath, rootPath),
    );
    if (existingIndex >= 0) {
      final existing = _libraries[existingIndex];
      final selected = existing.copyWith(
        rootPath: rootPath,
        bookmark: bookmark ?? existing.bookmark,
        displayName: path.basename(rootPath),
        rank: 0,
      );
      _libraries = [selected];
      _activeLibraryId = existing.id;
      _lastLibraryRoot = rootPath;
      _lastLibraryBookmark = selected.bookmark;
      return;
    }

    final entry = LibraryRegistryEntry(
      id: _uuid.v4(),
      displayName: path.basename(rootPath),
      rootPath: rootPath,
      bookmark: bookmark,
      rank: 0,
    );
    _libraries = [entry];
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

  /// Opens the app-support temporary library and clears any saved folder choice.
  Future<void> startWithTemporaryLibrary() async {
    try {
      await flushPending();
      _clearChosenLibraryPointers();
      await _repository.closeLibrary();
      await _repository.openDefaultLibrary();
      await _saveLayout();
      await _loadLibraryContent();
      _error = null;
      _recoveredToTemporaryLibrary = false;
    } on Object catch (error) {
      _library = null;
      _error = error;
    }
    notifyListeners();
    if (_error == null) {
      await onLibraryLoaded?.call();
    }
  }

  Future<void> load() async {
    _recoveredToTemporaryLibrary = false;
    try {
      await flushPending();
      await _loadLayout();
      _applyLibrarySetupFlagFromLayout();
      await _loadLibraryContent();
      _error = null;
    } on Object catch (error) {
      if (await _recoverToTemporaryLibrary()) {
        _recoveredToTemporaryLibrary = true;
      } else {
        _library = null;
        _error = error;
      }
    }
    notifyListeners();
    if (_error == null) {
      await onLibraryLoaded?.call();
    }
  }

  void _applyLibrarySetupFlagFromLayout() {
    if (_activeLibraryId != null || _lastLibraryRoot != null) {
      _needsLibrarySetup = false;
    } else if (_layoutRepository != null) {
      // A persisted layout with no chosen folder means temporary-library mode.
      _needsLibrarySetup = true;
    }
  }

  Future<void> _loadLibraryContent() async {
    if (_repository.location == null) {
      await _repository.openDefaultLibrary();
    }
    _library = await _repository.loadLibrary();
    _articleEditorStates = await _repository.loadArticleEditorStates();
    _restoreSelection();
    await _restoreArticle();
    _recoverableDrafts = await _repository.listDraftsNewerThanArticles();
  }

  void _clearChosenLibraryPointers() {
    _lastLibraryRoot = null;
    _lastLibraryBookmark = null;
    _activeLibraryId = null;
    _libraries = const [];
    _needsLibrarySetup = true;
    _resetBookUiState();
  }

  Future<bool> _recoverToTemporaryLibrary() async {
    try {
      _clearChosenLibraryPointers();
      await _repository.closeLibrary();
      await _repository.openDefaultLibrary();
      await _saveLayout();
      await _loadLibraryContent();
      _error = null;
      return true;
    } on Object {
      return false;
    }
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

  /// Appends a chapter to [volumeId] in the stored manual order.
  Future<void> appendChapterToVolume(String volumeId) async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.isTrash) return;
    final volume = _library?.categories
        .where((category) => category.id == volumeId)
        .firstOrNull;
    if (volume == null || volume.folderId != book.id) return;
    await flushPending();
    _article = await _repository.createArticle(
      folderId: book.id,
      categoryId: volumeId,
    );
    _selectedArticleId = _article?.id;
    _expandedVolumesByBook[book.id]?.add(volumeId);
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
    final removedIds =
        _library?.articles
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
    _articleEditorStates.remove(articleId);
    _pendingEditorStateArticleIds.remove(articleId);
    await _repository.clearArticleEditorState(articleId);
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

  /// Moves a chapter into another book as unfiled.
  Future<void> moveChapterToBook({
    required String articleId,
    required String folderId,
  }) async {
    if (isReadOnly) return;
    if (folderId == WritingFolder.trashId) return;
    final source = selectedBook;
    if (source == null || source.isTrash || source.id == folderId) return;
    await flushPending();
    await _repository.moveArticleToFolder(
      articleId: articleId,
      folderId: folderId,
    );
    if (_article?.id == articleId) {
      _article = await _repository.getArticle(articleId);
      _selectedBookId = folderId;
    }
    _scheduleLayoutSave();
    await load();
    notifyListeners();
  }

  /// Turns [volumeId] into a new book and selects that book.
  Future<WritingFolder?> convertVolumeToBook(String volumeId) async {
    if (isReadOnly) return null;
    final source = selectedBook;
    if (source == null || source.isTrash) return null;
    await flushPending();
    final folder = await _repository.convertCategoryToFolder(
      categoryId: volumeId,
    );
    _expandedVolumesByBook[source.id]?.remove(volumeId);
    _scheduleLayoutSave();
    await load();
    await selectBook(folder.id);
    return folder;
  }

  /// Moves a volume (and its chapters) into another book.
  Future<void> moveVolumeToBook({
    required String volumeId,
    required String folderId,
  }) async {
    if (isReadOnly) return;
    if (folderId == WritingFolder.trashId) return;
    final source = selectedBook;
    if (source == null || source.isTrash || source.id == folderId) return;
    await flushPending();
    await _repository.moveCategoryToFolder(
      categoryId: volumeId,
      folderId: folderId,
    );
    _expandedVolumesByBook[source.id]?.remove(volumeId);
    final expanded = _expandedVolumesByBook.putIfAbsent(
      folderId,
      () => <String>{},
    );
    expanded.add(volumeId);
    if (_article?.categoryId == volumeId) {
      _article = await _repository.getArticle(_article!.id);
      _selectedBookId = folderId;
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
      _runBackgroundSave(save);
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
      _runBackgroundSave(_persistTitle);
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

  Future<void> _persistTitle() async {
    var didPersist = false;
    while (_dirtyTitleArticleId != null && _dirtyTitle != null) {
      final articleId = _dirtyTitleArticleId!;
      final title = _dirtyTitle!;
      await _serializeWrite(
        () => _repository.renameArticle(articleId: articleId, title: title),
      );
      didPersist = true;
      if (_dirtyTitleArticleId == articleId && _dirtyTitle == title) {
        _dirtyTitleArticleId = null;
        _dirtyTitle = null;
      }
      _clearSaveErrorIfClean();
    }
    if (didPersist) {
      await _notifyLocalContentPersisted();
    }
  }

  Future<void> _notifyLocalContentPersisted() async {
    final hook = onLocalContentPersisted;
    if (hook == null) return;
    try {
      await hook();
    } on Object {
      // Pending-flag persistence must not block editor writes.
    }
  }

  /// Waits for every earlier write, then persists the latest content/title.
  /// A failed write remains pending and prevents exit or backup.
  Future<void> flushPending() async {
    _pendingSave?.cancel();
    _pendingSave = null;
    _pendingTitleSave?.cancel();
    _pendingTitleSave = null;
    try {
      do {
        await _writeTail;
        await save();
        await _persistTitle();
        await _writeTail;
      } while (_dirtyArticle != null || _dirtyTitleArticleId != null);
      _saveError = null;
    } on Object catch (error) {
      _saveError = error;
      notifyListeners();
      rethrow;
    }

    // Flush a pending layout write so last book/article survive pause/dispose.
    // Skip when nothing is queued — [load] also calls this and must not
    // overwrite disk with a still-null cold-start selection.
    if (_pendingLayoutSave != null) {
      await _flushLayout();
    }
    if (_pendingEditorStateSave != null ||
        _pendingEditorStateArticleIds.isNotEmpty) {
      await _flushEditorStateSave();
    }
    // Keep the legacy single-editor path synchronous after its own flush; the
    // root back handler intentionally starts its exit work unawaited.
    final companionFlush = flushMobileCompanion;
    if (companionFlush != null) {
      await companionFlush();
    }
  }

  Future<void> _flushLayout() async {
    _pendingLayoutSave?.cancel();
    _pendingLayoutSave = null;
    await _saveLayout();
  }

  void _scheduleEditorStateSave() {
    _pendingEditorStateSave?.cancel();
    _pendingEditorStateSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_flushEditorStateSave());
    });
  }

  Future<void> _flushEditorStateSave() async {
    _pendingEditorStateSave?.cancel();
    _pendingEditorStateSave = null;
    if (_pendingEditorStateArticleIds.isEmpty) return;
    final ids = List<String>.from(_pendingEditorStateArticleIds);
    _pendingEditorStateArticleIds.clear();
    for (final articleId in ids) {
      final state = _articleEditorStates[articleId];
      if (state == null) continue;
      try {
        await _repository.saveArticleEditorState(
          articleId: articleId,
          state: state,
        );
      } on Object {
        _pendingEditorStateArticleIds.add(articleId);
      }
    }
  }

  Future<void> save() async {
    _pendingSave?.cancel();
    var didPersist = false;
    while (_dirtyArticle != null) {
      final article = _dirtyArticle!;
      await _serializeWrite(() => _repository.saveArticle(article));
      didPersist = true;
      if (identical(_dirtyArticle, article)) {
        _dirtyArticle = null;
      }
      if (_article?.id == article.id) {
        _refreshSidebarPreviewIfNeeded(article);
      }
      _clearSaveErrorIfClean();
    }
    if (didPersist) {
      await _notifyLocalContentPersisted();
    }
  }

  void _scheduleDraftUpsert(WritingArticle article) {
    if (isReadOnly) return;
    final draft = ArticleDraft(
      articleId: article.id,
      content: article.content,
      title: article.title,
      updatedAt: DateTime.now(),
    );
    _runBackgroundSave(
      () => _serializeWrite(() => _repository.upsertDraft(draft)),
    );
  }

  /// All editor writes share one queue so an older draft or body cannot finish
  /// after a newer version or clear a newer recovery draft.
  Future<void> _serializeWrite(Future<void> Function() write) {
    final operation = _writeTail.then((_) => write());
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  void _runBackgroundSave(Future<void> Function() save) {
    unawaited(
      save().catchError((Object error, StackTrace stack) {
        _saveError = error;
        notifyListeners();
      }),
    );
  }

  void _clearSaveErrorIfClean() {
    if (_dirtyArticle != null ||
        _dirtyTitleArticleId != null ||
        _saveError == null) {
      return;
    }
    _saveError = null;
    notifyListeners();
  }

  Future<void> applyRecoverableDraft(ArticleDraft draft) async {
    await _repository.saveArticle(
      (await _repository.getArticle(draft.articleId))
          .copyWith(content: draft.content),
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
    if (_selectedArticleId == draft.articleId ||
        _article?.id == draft.articleId) {
      _article = await _repository.getArticle(draft.articleId);
    }
    _contentDirtySinceBackup = true;
    await _notifyLocalContentPersisted();
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
    markMobileCompanionBackupCompleted?.call();
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
    _article = chosen == null ? null : await _repository.getArticle(chosen.id);
  }

  Future<void> _loadLayout() async {
    final layoutRepository = _layoutRepository;
    if (layoutRepository == null) {
      return;
    }
    try {
      final layout = await layoutRepository.load();
      final selected = layout.activeLibrary ?? layout.libraries.firstOrNull;
      _sidebarWidth = layout.sidebarWidth;
      _lastLibraryRoot = selected?.rootPath ?? layout.lastLibraryRoot;
      _lastLibraryBookmark = selected?.bookmark ?? layout.lastLibraryBookmark;
      _activeLibraryId = selected?.id;
      _libraries = selected == null
          ? const []
          : [
              selected.copyWith(
                displayName: path.basename(selected.rootPath),
                rank: 0,
              ),
            ];
      // Keep an in-session selection across library refreshes (e.g. reorder).
      // Disk may still be null/stale when selection was only restored in memory.
      _selectedBookId ??= layout.selectedBookId;
      _selectedArticleId ??= layout.selectedArticleId;
      _mobileCompanionBookId ??= layout.mobileCompanionBookId;
      _mobileCompanionArticleId ??= layout.mobileCompanionArticleId;
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
          mobileCompanionBookId: _mobileCompanionBookId,
          mobileCompanionArticleId: _mobileCompanionArticleId,
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
