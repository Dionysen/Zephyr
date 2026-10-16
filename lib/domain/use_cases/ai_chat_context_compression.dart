import '../llm/llm_message_budget.dart';
import '../models/ai_chat_session.dart';
import '../models/llm_chat.dart';

/// Heuristic for when to summarize older turns into [AiChatSession.contextSummary].
bool aiChatShouldCompressHistory({
  required List<AiChatStoredMessage> messages,
  required int maxInputTokens,
  String contextSummary = '',
}) {
  if (messages.length < 12) return false;
  final budget = charsForTokenBudget(maxInputTokens);
  final chars = contextSummary.length +
      messages.fold<int>(
        0,
        (sum, m) => sum + m.body.length + m.thinking.length,
      );
  return chars > (budget * 0.82).round();
}

/// Builds the transcript block to summarize (oldest turns only).
String aiChatTranscriptForCompression(
  List<AiChatStoredMessage> messages, {
  int keepRecent = 8,
}) {
  if (messages.length <= keepRecent) return '';
  final old = messages.sublist(0, messages.length - keepRecent);
  final lines = <String>[];
  for (final message in old) {
    final label = message.role == AiChatMessageRole.user ? 'User' : 'Assistant';
    final body = message.body.trim();
    if (body.isEmpty) continue;
    lines.add('$label: $body');
  }
  return lines.join('\n\n');
}

List<LlmChatMessage> aiChatCompressionSummaryRequest(String transcript) => [
  LlmChatMessage(
    role: LlmChatRole.system,
    text:
        'Summarize the following conversation for use as compact context in a '
        'later turn. Preserve facts, decisions, names, and open tasks. Use the '
        'same language as the transcript. Output only the summary, no preamble.',
  ),
  LlmChatMessage(role: LlmChatRole.user, text: transcript),
];

String mergeAiChatContextSummaries({
  required String existing,
  required String addition,
}) {
  final parts = <String>[
    if (existing.trim().isNotEmpty) existing.trim(),
    if (addition.trim().isNotEmpty) addition.trim(),
  ];
  return parts.join('\n\n');
}
