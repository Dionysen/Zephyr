import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/article_editor_state.dart';

void main() {
  test('article editor state round-trips in ZephyrMeta', () async {
    final directory = await Directory.systemTemp.createTemp('zephyr-editor-state-');
    addTearDown(() => directory.delete(recursive: true));
    final database = PureWriterDatabase();
    await database.openLibrary(directory.path, createIfMissing: true);
    addTearDown(database.close);
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );

    const state = ArticleEditorState(
      scrollOffset: 240.5,
      selectionBase: 12,
      selectionExtent: 18,
      updatedAt: 1_700_000_000_000,
    );
    await repository.saveArticleEditorState(
      articleId: article.id,
      state: state,
    );

    final loaded = await repository.loadArticleEditorState(article.id);
    expect(loaded?.scrollOffset, state.scrollOffset);
    expect(loaded?.selectionBase, state.selectionBase);
    expect(loaded?.selectionExtent, state.selectionExtent);
    expect(loaded?.updatedAt, state.updatedAt);
    final map = await repository.loadArticleEditorStates();
    expect(map[article.id]?.scrollOffset, state.scrollOffset);

    await repository.clearArticleEditorState(article.id);
    expect(await repository.loadArticleEditorState(article.id), isNull);
  });

  test('ArticleEditorState.merge keeps the newer timestamp', () {
    const local = ArticleEditorState(
      scrollOffset: 1,
      selectionBase: 0,
      selectionExtent: 0,
      updatedAt: 10,
    );
    const remote = ArticleEditorState(
      scrollOffset: 99,
      selectionBase: 5,
      selectionExtent: 5,
      updatedAt: 20,
    );
    expect(ArticleEditorState.merge(local, remote), remote);
    expect(ArticleEditorState.merge(remote, local), remote);
  });
}
