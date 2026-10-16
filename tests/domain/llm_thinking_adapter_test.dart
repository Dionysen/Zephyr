import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/llm/llm_thinking_adapter.dart';
import 'package:zephyr/domain/models/llm_settings.dart';

void main() {
  test('OpenAI o-series uses reasoning_effort from level', () {
    final params = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.openai,
      level: LlmThinkingLevel.high,
      modelId: 'o3-mini',
    );
    expect(params.openAiReasoningEffort, 'high');
  });

  test('DeepSeek uses thinking block', () {
    final params = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.deepseek,
      level: LlmThinkingLevel.medium,
      modelId: 'deepseek-chat',
    );
    expect(params.openAiThinking, {'type': 'enabled'});
  });

  test('Anthropic maps level to budget_tokens', () {
    final params = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.anthropic,
      level: LlmThinkingLevel.low,
      modelId: 'claude-sonnet-4-20250514',
    );
    expect(params.anthropicThinking?['budget_tokens'], 4096);
  });

  test('off disables vendor thinking instead of omitting it', () {
    final gemini = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.google,
      level: LlmThinkingLevel.off,
      modelId: 'gemini-2.5-flash',
    );
    expect(gemini.googleThinkingBudget, 0);

    final deepseek = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.deepseek,
      level: LlmThinkingLevel.off,
      modelId: 'deepseek-chat',
    );
    expect(deepseek.openAiThinking, {'type': 'disabled'});

    final compatible = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.openAiCompatible,
      level: LlmThinkingLevel.off,
      modelId: 'qwen3',
    );
    expect(compatible.openAiThinking, {'type': 'disabled'});
    expect(compatible.enableThinking, isFalse);

    final oSeries = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.openai,
      level: LlmThinkingLevel.off,
      modelId: 'o3-mini',
    );
    expect(oSeries.openAiReasoningEffort, 'low');

    final gpt5 = LlmThinkingAdapter.forRequest(
      provider: LlmProviderKind.openai,
      level: LlmThinkingLevel.off,
      modelId: 'gpt-5',
    );
    expect(gpt5.openAiReasoningEffort, 'none');
  });
}
