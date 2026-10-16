import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/llm/llm_model_list_parsers.dart';
import '../../domain/llm/llm_provider_catalog.dart';
import '../../domain/llm/llm_thinking_adapter.dart';
import '../../domain/models/llm_chat.dart';
import '../../domain/models/llm_settings.dart';

class LlmGatewayException implements Exception {
  LlmGatewayException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP client for listing models and chat completions across vendors.
class LlmGateway {
  LlmGateway({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 45);

  Future<List<LlmModelOption>> listModels(LlmConnection connection) async {
    final key = connection.apiKey.trim();
    if (key.isEmpty) {
      throw LlmGatewayException('API key is required.');
    }
    return switch (connection.provider) {
      LlmProviderKind.anthropic => _listAnthropicModels(connection, key),
      LlmProviderKind.google => _listGoogleModels(connection, key),
      LlmProviderKind.openai ||
      LlmProviderKind.deepseek ||
      LlmProviderKind.zhipu ||
      LlmProviderKind.openAiCompatible => _listOpenAiCompatibleModels(
        connection,
        key,
      ),
    };
  }

  Future<String> completeChat({
    required LlmConnection connection,
    required String modelId,
    required List<LlmChatMessage> messages,
    required LlmCompletionOptions options,
  }) async {
    final key = connection.apiKey.trim();
    if (key.isEmpty) {
      throw LlmGatewayException('API key is required.');
    }
    if (modelId.isEmpty) {
      throw LlmGatewayException('Model is required.');
    }
    return switch (connection.provider) {
      LlmProviderKind.anthropic => _chatAnthropic(
        connection,
        key,
        modelId,
        messages,
        options,
      ),
      LlmProviderKind.google => _chatGoogle(
        connection,
        key,
        modelId,
        messages,
        options,
      ),
      LlmProviderKind.openai ||
      LlmProviderKind.deepseek ||
      LlmProviderKind.zhipu ||
      LlmProviderKind.openAiCompatible => _chatOpenAiCompatible(
        connection,
        key,
        modelId,
        messages,
        options,
      ),
    };
  }

  Stream<String> streamChat({
    required LlmConnection connection,
    required String modelId,
    required List<LlmChatMessage> messages,
    required LlmCompletionOptions options,
  }) async* {
    final key = connection.apiKey.trim();
    if (key.isEmpty) {
      throw LlmGatewayException('API key is required.');
    }
    if (modelId.isEmpty) {
      throw LlmGatewayException('Model is required.');
    }
    switch (connection.provider) {
      case LlmProviderKind.anthropic:
      case LlmProviderKind.google:
        yield await completeChat(
          connection: connection,
          modelId: modelId,
          messages: messages,
          options: options,
        );
        return;
      case LlmProviderKind.openai:
      case LlmProviderKind.deepseek:
      case LlmProviderKind.zhipu:
      case LlmProviderKind.openAiCompatible:
        yield* _streamOpenAiCompatible(
          connection,
          key,
          modelId,
          messages,
          options,
        );
    }
  }

  Future<List<LlmModelOption>> _listOpenAiCompatibleModels(
    LlmConnection connection,
    String key,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    if (root.isEmpty) {
      throw LlmGatewayException('Base URL is required.');
    }
    final uri = Uri.parse('$root/models');
    final response = await _client
        .get(uri, headers: _bearerHeaders(key))
        .timeout(_timeout);
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return parseOpenAiCompatibleModelList(json);
  }

  Future<List<LlmModelOption>> _listAnthropicModels(
    LlmConnection connection,
    String key,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    final uri = Uri.parse('$root/models');
    final response = await _client
        .get(
          uri,
          headers: {
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
        )
        .timeout(_timeout);
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return parseAnthropicModelList(json);
  }

  Future<List<LlmModelOption>> _listGoogleModels(
    LlmConnection connection,
    String key,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    final uri = Uri.parse('$root/models').replace(queryParameters: {'key': key});
    final response = await _client.get(uri).timeout(_timeout);
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return parseGoogleModelList(json);
  }

  Map<String, Object?> _openAiChatBody(
    LlmConnection connection,
    String modelId,
    List<LlmChatMessage> messages,
    LlmCompletionOptions options, {
    required bool stream,
  }) {
    final body = <String, Object?>{
      'model': modelId,
      'stream': stream,
      'max_tokens': options.maxOutputTokens,
      'messages': [
        for (final message in messages)
          {'role': message.role.apiName, 'content': message.text},
      ],
    };
    _applyOpenAiThinking(body, options);
    return body;
  }

  void _applyOpenAiThinking(
    Map<String, Object?> body,
    LlmCompletionOptions options,
  ) {
    final thinking = LlmThinkingAdapter.forRequest(
      provider: options.provider,
      level: options.thinkingLevel,
      modelId: options.modelId,
    );
    if (thinking.openAiReasoningEffort != null) {
      body['reasoning_effort'] = thinking.openAiReasoningEffort;
    }
    if (thinking.openAiThinking != null) {
      body['thinking'] = thinking.openAiThinking;
    }
  }

  Future<String> _chatOpenAiCompatible(
    LlmConnection connection,
    String key,
    String modelId,
    List<LlmChatMessage> messages,
    LlmCompletionOptions options,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    if (root.isEmpty) {
      throw LlmGatewayException('Base URL is required.');
    }
    final uri = Uri.parse('$root/chat/completions');
    final body = jsonEncode(
      _openAiChatBody(connection, modelId, messages, options, stream: false),
    );
    final response = await _client
        .post(uri, headers: _bearerHeaders(key), body: body)
        .timeout(_timeout);
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String) return content.trim();
        }
      }
    }
    throw LlmGatewayException('Empty response from model.');
  }

  Stream<String> _streamOpenAiCompatible(
    LlmConnection connection,
    String key,
    String modelId,
    List<LlmChatMessage> messages,
    LlmCompletionOptions options,
  ) async* {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    if (root.isEmpty) {
      throw LlmGatewayException('Base URL is required.');
    }
    final uri = Uri.parse('$root/chat/completions');
    final request = http.Request('POST', uri);
    request.headers.addAll(_bearerHeaders(key));
    request.headers['accept'] = 'text/event-stream';
    request.body = jsonEncode(
      _openAiChatBody(connection, modelId, messages, options, stream: true),
    );
    final response = await _client.send(request).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw LlmGatewayException(
        body.isEmpty ? 'HTTP ${response.statusCode}' : body,
        statusCode: response.statusCode,
      );
    }
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        final payload = trimmed.substring(5).trim();
        if (payload == '[DONE]') return;
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final choices = json['choices'];
          if (choices is! List || choices.isEmpty) continue;
          final first = choices.first;
          if (first is! Map) continue;
          final delta = first['delta'];
          if (delta is! Map) continue;
          final content = delta['content'];
          if (content is String && content.isNotEmpty) yield content;
        } on Object {
          continue;
        }
      }
    }
  }

  Future<String> _chatAnthropic(
    LlmConnection connection,
    String key,
    String modelId,
    List<LlmChatMessage> messages,
    LlmCompletionOptions options,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    final uri = Uri.parse('$root/messages');
    final system = messages
        .where((m) => m.role == LlmChatRole.system)
        .map((m) => m.text)
        .join('\n\n');
    final turns = messages
        .where((m) => m.role != LlmChatRole.system)
        .map(
          (m) => {
            'role': m.role == LlmChatRole.assistant ? 'assistant' : 'user',
            'content': m.text,
          },
        )
        .toList(growable: false);
    final bodyMap = <String, Object?>{
      'model': modelId,
      'max_tokens': options.maxOutputTokens,
      if (system.isNotEmpty) 'system': system,
      'messages': turns,
    };
    final thinking = LlmThinkingAdapter.forRequest(
      provider: options.provider,
      level: options.thinkingLevel,
      modelId: options.modelId,
    );
    if (thinking.anthropicThinking != null) {
      bodyMap['thinking'] = thinking.anthropicThinking;
    }
    final body = jsonEncode(bodyMap);
    final response = await _client
        .post(
          uri,
          headers: {
            'x-api-key': key,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: body,
        )
        .timeout(_timeout);
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['content'];
    if (content is List) {
      for (final block in content) {
        if (block is Map && block['type'] == 'text') {
          final text = block['text'];
          if (text is String && text.isNotEmpty) return text.trim();
        }
      }
    }
    throw LlmGatewayException('Empty response from model.');
  }

  Future<String> _chatGoogle(
    LlmConnection connection,
    String key,
    String modelId,
    List<LlmChatMessage> messages,
    LlmCompletionOptions options,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    final uri = Uri.parse('$root/models/$modelId:generateContent').replace(
      queryParameters: {'key': key},
    );
    final contents = <Map<String, Object?>>[];
    for (final message in messages.where((m) => m.role != LlmChatRole.system)) {
      contents.add({
        'role': message.role == LlmChatRole.assistant ? 'model' : 'user',
        'parts': [
          {'text': message.text},
        ],
      });
    }
    final system = messages
        .where((m) => m.role == LlmChatRole.system)
        .map((m) => m.text)
        .join('\n\n');
    final thinking = LlmThinkingAdapter.forRequest(
      provider: options.provider,
      level: options.thinkingLevel,
      modelId: options.modelId,
    );
    final generationConfig = <String, Object?>{
      'maxOutputTokens': options.maxOutputTokens,
    };
    if (thinking.googleThinkingBudget != null) {
      generationConfig['thinkingConfig'] = {
        'thinkingBudget': thinking.googleThinkingBudget,
      };
    }
    final body = jsonEncode({
      if (system.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
      'contents': contents,
      'generationConfig': generationConfig,
    });
    final response = await _client
        .post(
          uri,
          headers: {'content-type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List) {
            for (final part in parts) {
              if (part is Map) {
                final text = part['text'];
                if (text is String && text.isNotEmpty) return text.trim();
              }
            }
          }
        }
      }
    }
    throw LlmGatewayException('Empty response from model.');
  }

  Map<String, String> _bearerHeaders(String key) => {
    'authorization': 'Bearer $key',
    'content-type': 'application/json',
  };

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String detail = response.body;
    if (detail.length > 240) {
      detail = '${detail.substring(0, 240)}…';
    }
    throw LlmGatewayException(
      detail.isEmpty ? 'HTTP ${response.statusCode}' : detail,
      statusCode: response.statusCode,
    );
  }
}
