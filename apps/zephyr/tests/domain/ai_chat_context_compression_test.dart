import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/ai_chat_session.dart';
import 'package:zephyr/domain/use_cases/ai_chat_context_compression.dart';

void main() {
  test('shouldCompress when history is long or large', () {
    final messages = List<AiChatStoredMessage>.generate(
      14,
      (i) => AiChatStoredMessage(
        id: '$i',
        sessionId: 's',
        role: i.isEven ? AiChatMessageRole.user : AiChatMessageRole.assistant,
        body: 'word ' * 200,
        sortOrder: i,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    expect(
      aiChatShouldCompressHistory(messages: messages, maxInputTokens: 4096),
      isTrue,
    );
  });

  test('transcript keeps only older turns', () {
    final messages = List<AiChatStoredMessage>.generate(
      10,
      (i) => AiChatStoredMessage(
        id: '$i',
        sessionId: 's',
        role: AiChatMessageRole.user,
        body: 'line $i',
        sortOrder: i,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    final text = aiChatTranscriptForCompression(messages, keepRecent: 3);
    expect(text, contains('line 0'));
    expect(text, isNot(contains('line 9')));
  });
}
