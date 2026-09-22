import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../../domain/repositories/writing_library_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(this._repository);
  final WritingLibraryRepository _repository;
  WritingLibrary? _library;
  WritingArticle? _article;
  Object? _error;
  Timer? _pendingSave;
  WritingLibrary? get library => _library;
  WritingArticle? get article => _article;
  Object? get error => _error;
  Future<void> load() async {
    try {
      _library = await _repository.loadLibrary();
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
