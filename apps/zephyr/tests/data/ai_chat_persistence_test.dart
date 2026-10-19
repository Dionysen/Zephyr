import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/ai_chat_session.dart';

void main() {
  test('AI chat sessions round-trip in Room.db', () async {
    final directory = await Directory.systemTemp.createTemp('zephyr-ai-chat-');
    addTearDown(() => directory.delete(recursive: true));
    final database = PureWriterDatabase();
    await database.openLibrary(directory.path, createIfMissing: true);
    addTearDown(database.close);
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );

    final session = await repository.createAiChatSession(
      articleId: article.id,
      title: 'Test chat',
    );
    await repository.appendAiChatMessage(
      sessionId: session.id,
      role: AiChatMessageRole.user,
      body: '「第一章」',
      modelBody: '## 第一章\n\n正文',
    );
    await repository.appendAiChatMessage(
      sessionId: session.id,
      role: AiChatMessageRole.assistant,
      body: 'Hi',
    );

    final sessions = await repository.listAiChatSessions(article.id);
    expect(sessions, hasLength(1));
    expect(sessions.first.title, 'Test chat');

    final messages = await repository.listAiChatMessages(session.id);
    expect(messages, hasLength(2));
    expect(messages.first.body, '「第一章」');
    expect(messages.first.promptBody, '## 第一章\n\n正文');
    expect(messages.last.body, 'Hi');

    await repository.archiveAiChatSession(session.id, archived: true);
    final active = await repository.listAiChatSessions(article.id);
    expect(active, isEmpty);
    final archived = await repository.listAiChatSessions(
      article.id,
      includeArchived: true,
    );
    expect(archived.first.archived, isTrue);
  });
}
