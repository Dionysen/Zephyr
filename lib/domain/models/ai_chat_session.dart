/// Navigation token: ephemeral new chat (no DB row until the first user message).
const kAiChatNewConversation = '__zephyr_new_ai_chat__';

/// Persisted AI chat session scoped to a single article (Room.db / `.pwb`).
class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.articleId,
    required this.title,
    required this.archived,
    required this.contextSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String articleId;
  final String title;
  final bool archived;

  /// Rolling summary of older turns after automatic context compression.
  final String contextSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiChatSession copyWith({
    String? title,
    bool? archived,
    String? contextSummary,
    DateTime? updatedAt,
  }) => AiChatSession(
    id: id,
    articleId: articleId,
    title: title ?? this.title,
    archived: archived ?? this.archived,
    contextSummary: contextSummary ?? this.contextSummary,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum AiChatMessageRole { user, assistant }

class AiChatStoredMessage {
  const AiChatStoredMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.body,
    this.thinking = '',
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final AiChatMessageRole role;
  final String body;
  final String thinking;
  final int sortOrder;
  final DateTime createdAt;
}
