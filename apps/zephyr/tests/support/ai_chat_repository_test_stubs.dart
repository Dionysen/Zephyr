import 'package:zephyr/domain/models/ai_chat_session.dart';

/// Default AI chat persistence for [WritingLibraryRepository] test fakes.
mixin AiChatRepositoryMethods {
  Future<List<AiChatSession>> listAiChatSessions(
    String articleId, {
    bool includeArchived = false,
  }) async =>
      [];

  Future<AiChatSession?> loadActiveAiChatSession(String articleId) async => null;

  Future<void> beginNewAiChatConversation(String articleId) async {}

  Future<AiChatSession?> getAiChatSession(String sessionId) async => null;

  Future<AiChatSession> createAiChatSession({
    required String articleId,
    String? title,
  }) async =>
      AiChatSession(
        id: 'stub-session',
        articleId: articleId,
        title: 'stub',
        archived: false,
        contextSummary: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  Future<void> setActiveAiChatSession({
    required String articleId,
    required String sessionId,
  }) async {}

  Future<void> renameAiChatSession({
    required String sessionId,
    required String title,
  }) async {}

  Future<void> archiveAiChatSession(
    String sessionId, {
    required bool archived,
  }) async {}

  Future<void> deleteAiChatSession(String sessionId) async {}

  Future<List<AiChatStoredMessage>> listAiChatMessages(String sessionId) async =>
      [];

  Future<AiChatStoredMessage> appendAiChatMessage({
    required String sessionId,
    required AiChatMessageRole role,
    required String body,
    String thinking = '',
    String modelBody = '',
  }) async =>
      AiChatStoredMessage(
        id: 'stub-msg',
        sessionId: sessionId,
        role: role,
        body: body,
        modelBody: modelBody,
        thinking: thinking,
        sortOrder: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  Future<void> updateAiChatMessage({
    required String messageId,
    required String body,
    String thinking = '',
  }) async {}

  Future<void> updateAiChatSessionSummary({
    required String sessionId,
    required String contextSummary,
  }) async {}

  Future<void> pruneAiChatMessagesBefore({
    required String sessionId,
    required int keepFromSortOrder,
  }) async {}

  Future<double?> loadAiChatScrollOffset({
    required String articleId,
    String? sessionId,
  }) async =>
      null;

  Future<void> saveAiChatScrollOffset({
    required String articleId,
    String? sessionId,
    required double offset,
  }) async {}
}
