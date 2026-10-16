import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/repositories/zephyr_ai_chat_store.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/ai_chat_session.dart';

void main() {
  test('ai chat scroll offsets round-trip per session and article', () async {
    final directory = await Directory.systemTemp.createTemp('zephyr-ai-scroll-');
    addTearDown(() => directory.delete(recursive: true));
    final database = PureWriterDatabase();
    await database.openLibrary(directory.path, createIfMissing: true);
    addTearDown(database.close);
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );

    await repository.saveAiChatScrollOffset(
      articleId: article.id,
      sessionId: null,
      offset: 120,
    );
    expect(
      await repository.loadAiChatScrollOffset(
        articleId: article.id,
        sessionId: null,
      ),
      120,
    );

    final session = await repository.createAiChatSession(articleId: article.id);
    await repository.appendAiChatMessage(
      sessionId: session.id,
      role: AiChatMessageRole.user,
      body: 'Hi',
    );
    await repository.saveAiChatScrollOffset(
      articleId: article.id,
      sessionId: session.id,
      offset: 480.5,
    );
    expect(
      await repository.loadAiChatScrollOffset(
        articleId: article.id,
        sessionId: session.id,
      ),
      480.5,
    );
    expect(
      ZephyrAiChatStore.scrollOffsetKey(articleId: article.id, sessionId: null),
      'article:${article.id}',
    );
    expect(
      ZephyrAiChatStore.scrollOffsetKey(
        articleId: article.id,
        sessionId: session.id,
      ),
      session.id,
    );

    await repository.saveAiChatScrollOffset(
      articleId: article.id,
      sessionId: session.id,
      offset: 0,
    );
    expect(
      await repository.loadAiChatScrollOffset(
        articleId: article.id,
        sessionId: session.id,
      ),
      isNull,
    );
  });
}
