import '../models/llm_settings.dart';

/// Static endpoint metadata per [LlmProviderKind].
abstract final class LlmProviderCatalog {
  static String labelZh(LlmProviderKind kind) => switch (kind) {
    LlmProviderKind.openai => 'OpenAI',
    LlmProviderKind.deepseek => 'DeepSeek',
    LlmProviderKind.anthropic => 'Claude (Anthropic)',
    LlmProviderKind.google => 'Google Gemini',
    LlmProviderKind.zhipu => '智谱 GLM',
    LlmProviderKind.openAiCompatible => 'OpenAI 兼容',
  };

  static String labelEn(LlmProviderKind kind) => switch (kind) {
    LlmProviderKind.openai => 'OpenAI',
    LlmProviderKind.deepseek => 'DeepSeek',
    LlmProviderKind.anthropic => 'Anthropic (Claude)',
    LlmProviderKind.google => 'Google Gemini',
    LlmProviderKind.zhipu => 'Zhipu GLM',
    LlmProviderKind.openAiCompatible => 'OpenAI-compatible',
  };

  /// API root without trailing slash (OpenAI-style roots include `/v1` where needed).
  static String defaultApiRoot(LlmProviderKind kind) => switch (kind) {
    LlmProviderKind.openai => 'https://api.openai.com/v1',
    LlmProviderKind.deepseek => 'https://api.deepseek.com/v1',
    LlmProviderKind.anthropic => 'https://api.anthropic.com/v1',
    LlmProviderKind.google => 'https://generativelanguage.googleapis.com/v1beta',
    LlmProviderKind.zhipu => 'https://open.bigmodel.cn/api/paas/v4',
    LlmProviderKind.openAiCompatible => '',
  };

  static String resolveApiRoot(LlmConnection connection) {
    if (connection.provider == LlmProviderKind.openAiCompatible) {
      return _normalizeRoot(connection.customBaseUrl);
    }
    return defaultApiRoot(connection.provider);
  }

  static String _normalizeRoot(String raw) {
    var value = raw.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
