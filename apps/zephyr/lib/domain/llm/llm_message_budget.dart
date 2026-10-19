import '../models/llm_chat.dart';

/// Rough char budget from token limit (~4 Latin chars / token).
int charsForTokenBudget(int tokens) => tokens.clamp(1024, 2000000) * 4;

/// Drops oldest non-system turns until estimated size fits [maxInputTokens].
List<LlmChatMessage> truncateMessagesForBudget(
  List<LlmChatMessage> messages, {
  required int maxInputTokens,
}) {
  if (messages.isEmpty) return messages;
  final budget = charsForTokenBudget(maxInputTokens);
  final system = messages.where((m) => m.role == LlmChatRole.system).toList();
  final rest = messages.where((m) => m.role != LlmChatRole.system).toList();
  var total = _size(system) + _size(rest);
  while (rest.length > 1 && total > budget) {
    rest.removeAt(0);
    total = _size(system) + _size(rest);
  }
  return [...system, ...rest];
}

int _size(List<LlmChatMessage> messages) =>
    messages.fold<int>(0, (sum, m) => sum + m.text.length);
