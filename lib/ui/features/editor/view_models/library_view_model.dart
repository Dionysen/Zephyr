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
  }) : _error = initialError;
  final WritingLibraryRepository _repository;
  final WorkspaceLayoutRepository? _layoutRepository;
  WritingLibrary? _library;
  WritingArticle? _article;
  Object? _error;
  Timer? _pendingSave;
  Timer? _pendingLayoutSave;
  bool _isSidebarExpanded = true;
  bool _isResizingSidebar = false;
  double _sidebarWidth = WorkspaceLayout.defaults.sidebarWidth;
  final Set<String> _expandedVolumeIds = <String>{};
  String? _selectedBookId;
  static const minSidebarWidth = WorkspaceLayout.minSidebarWidth;
  static const maxSidebarWidth = WorkspaceLayout.maxSidebarWidth;
  static const defaultSidebarWidth = WorkspaceLayout.defaultSidebarWidth;
  WritingLibrary? get library => _library;
  WritingArticle? get article => _article;
  Object? get error => _error;
  bool get isLibraryInUse => _error is LibraryInUseException;
  bool get isReadOnly => _repository.location?.schema.writesAllowed == false;
  bool get isSidebarExpanded => _isSidebarExpanded;
  bool get isResizingSidebar => _isResizingSidebar;
  double get sidebarWidth => _sidebarWidth;
  bool get hasVolumes => _volumesForSelectedBook.isNotEmpty;
  bool get areAllVolumesExpanded =>
      hasVolumes &&
      _volumesForSelectedBook.every(
        (volume) => _expandedVolumeIds.contains(volume.id),
      );
  WritingFolder? get selectedBook =>
      _library?.folders.where((book) => book.id == _selectedBookId).firstOrNull;
  String get libraryName {
    final name = path.basename(_repository.location?.rootPath ?? '');
    return name.isEmpty ? 'Untitled library' : name;
  }

  bool isVolumeExpanded(String volumeId) =>
      _expandedVolumeIds.contains(volumeId);

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }

  void toggleVolume(String volumeId) {
    if (!_expandedVolumeIds.add(volumeId)) _expandedVolumeIds.remove(volumeId);
    notifyListeners();
  }

  void toggleAllVolumes() {
    if (!hasVolumes) return;
    if (areAllVolumesExpanded) {
      _expandedVolumeIds.removeAll(
        _volumesForSelectedBook.map((volume) => volume.id),
      );
    } else {
      _expandedVolumeIds.addAll(
        _volumesForSelectedBook.map((volume) => volume.id),
      );
    }
    notifyListeners();
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
    _selectedBookId = bookId;
    _expandedVolumeIds
      ..clear()
      ..addAll(_volumesForSelectedBook.map((volume) => volume.id));
    final firstChapter = _chaptersForSelectedBook.firstOrNull;
    _article = firstChapter == null
        ? null
        : await _repository.getArticle(firstChapter.id);
    notifyListeners();
  }

  Future<void> openLibrary(String rootPath) async {
    try {
      await _repository.openLibrary(rootPath);
      _expandedVolumeIds.clear();
      await load();
    } on Object catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  Future<void> load() async {
    try {
      await _loadLayout();
      _library = await _repository.loadLibrary();
      _selectedBookId ??=
          _library!.folders
              .where((book) => book.id != 'PW_Trash')
              .firstOrNull
              ?.id ??
          _library!.folders.firstOrNull?.id;
      _expandedVolumeIds.addAll(
        _volumesForSelectedBook.map((volume) => volume.id),
      );
      final firstChapter = _chaptersForSelectedBook.firstOrNull;
      _article = firstChapter == null
          ? null
          : await _repository.getArticle(firstChapter.id);
    } on Object catch (error) {
      _error = error;
    }
    notifyListeners();
  }

  Future<void> selectArticle(String id) async {
    _article = await _repository.getArticle(id);
    notifyListeners();
  }

  Future<void> createArticle() async {
    if (isReadOnly) return;
    final book = selectedBook;
    if (book == null || book.id == 'PW_Trash') return;
    _article = await _repository.createArticle(folderId: book.id);
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
      updatedAt: DateTime.now(),
    );
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 500), save);
    notifyListeners();
  }

  Future<void> save() async {
    _pendingSave?.cancel();
    final article = _article;
    if (article != null) await _repository.saveArticle(article);
  }

  Future<void> _loadLayout() async {
    final layoutRepository = _layoutRepository;
    if (layoutRepository == null) {
      return;
    }
    try {
      final layout = await layoutRepository.load();
      _sidebarWidth = layout.sidebarWidth;
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
        WorkspaceLayout(sidebarWidth: _sidebarWidth),
      );
    } on Object {
      // The in-memory width remains usable if layout storage is unavailable.
    }
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
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
