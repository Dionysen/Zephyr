import 'package:zephyr/domain/models/article_editor_state.dart';

/// Default editor-state persistence for [WritingLibraryRepository] test fakes.
mixin ArticleEditorStateRepositoryMethods {
  Future<Map<String, ArticleEditorState>> loadArticleEditorStates() async =>
      {};

  Future<ArticleEditorState?> loadArticleEditorState(String articleId) async =>
      null;

  Future<void> saveArticleEditorState({
    required String articleId,
    required ArticleEditorState state,
  }) async {}

  Future<void> clearArticleEditorState(String articleId) async {}
}
