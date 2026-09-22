import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../../../domain/models/purewriter_models.dart';
import '../../../../domain/repositories/writing_library_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(this._repository, {Object? initialError})
    : _error = initialError;
  final WritingLibraryRepository _repository;
  WritingLibrary? _library;
  WritingArticle? _article;
  Object? _error;
  Timer? _pendingSave;
  bool _isSidebarExpanded = true;
  final Set<String> _expandedFolderIds = <String>{};
  WritingLibrary? get library => _library;
  WritingArticle? get article => _article;
  Object? get error => _error;
  bool get isLibraryInUse => _error is LibraryInUseException;
  bool get isReadOnly => _repository.location?.schema.writesAllowed == false;
  bool get isSidebarExpanded => _isSidebarExpanded;
  String get bookName {
    final name = path.basename(_repository.location?.rootPath ?? '');
    return name.isEmpty ? 'Untitled book' : name;
  }

  bool isFolderExpanded(String folderId) =>
      _expandedFolderIds.contains(folderId);

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }

  void toggleFolder(String folderId) {
    if (!_expandedFolderIds.add(folderId)) _expandedFolderIds.remove(folderId);
    notifyListeners();
  }

  Future<void> openLibrary(String rootPath) async {
    try {
      await _repository.openLibrary(rootPath);
      _expandedFolderIds.clear();
      await load();
    } on Object catch (error) {
      _error = error;
      notifyListeners();
    }
  }

  Future<void> load() async {
    try {
      _library = await _repository.loadLibrary();
      _expandedFolderIds.addAll(_library!.folders.map((folder) => folder.id));
      if (_library!.articles.isNotEmpty) {
        _article = await _repository.getArticle(_library!.articles.first.id);
      }
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
    final folder = _library?.folders
        .where((item) => item.id != 'PW_Trash')
        .firstOrNull;
    if (folder == null) return;
    _article = await _repository.createArticle(folderId: folder.id);
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

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
