import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/ai_chat_session.dart';

void main() {
  test('empty sessions are not active until first message', () async {
    final directory = await Directory.systemTemp.createTemp('zephyr-ai-eph-');
    addTearDown(() => directory.delete(recursive: true));
    final database = PureWriterDatabase();
    await database.openLibrary(directory.path, createIfMissing: true);
    addTearDown(database.close);
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );

    expect(await repository.loadActiveAiChatSession(article.id), isNull);

    final session = await repository.createAiChatSession(articleId: article.id);
    expect(await repository.listAiChatMessages(session.id), isEmpty);
    expect(await repository.loadActiveAiChatSession(article.id), isNull);

    await repository.appendAiChatMessage(
      sessionId: session.id,
      role: AiChatMessageRole.user,
      body: 'Hi',
    );
    await repository.setActiveAiChatSession(
      articleId: article.id,
      sessionId: session.id,
    );
    final loaded = await repository.loadActiveAiChatSession(article.id);
    expect(loaded?.id, session.id);

    await repository.beginNewAiChatConversation(article.id);
    expect(await repository.loadActiveAiChatSession(article.id), isNull);
    expect(await repository.listAiChatSessions(article.id), hasLength(1));
  });
}
