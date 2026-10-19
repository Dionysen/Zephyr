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

/// User stopped an in-flight chat request before it finished.
class LlmChatCancelledException implements Exception {
  @override
  String toString() => 'Chat request cancelled.';
}

/// HTTP client for listing models and chat completions across vendors.
class LlmGateway {
  LlmGateway({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 45);

  http.Client? _cancellableClient;
  var _chatCancelRequested = false;

  bool get chatCancelRequested => _chatCancelRequested;

  void cancelActiveChat() {
    _chatCancelRequested = true;
    _cancellableClient?.close();
  }

  http.Client _openCancellableChat() {
    _chatCancelRequested = false;
    final client = http.Client();
    _cancellableClient = client;
    return client;
  }

  void _closeCancellableChat(http.Client client) {
    if (_cancellableClient == client) {
      _cancellableClient = null;
    }
    client.close();
  }

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

  Future<LlmChatResult> completeChat({
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
    final client = _openCancellableChat();
    try {
      final result = await switch (connection.provider) {
        LlmProviderKind.anthropic => _chatAnthropic(
          client,
          connection,
          key,
          modelId,
          messages,
          options,
        ),
        LlmProviderKind.google => _chatGoogle(
          client,
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
          client,
          connection,
          key,
          modelId,
          messages,
          options,
        ),
      };
      if (_chatCancelRequested) {
        throw LlmChatCancelledException();
      }
      return _present(result, options);
    } on LlmChatCancelledException {
      rethrow;
    } on Object {
      if (_chatCancelRequested) {
        throw LlmChatCancelledException();
      }
      rethrow;
    } finally {
      _closeCancellableChat(client);
    }
  }

  Stream<LlmStreamPart> streamChat({
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
    final client = _openCancellableChat();
    try {
      switch (connection.provider) {
        case LlmProviderKind.anthropic:
          final anthropic = await _chatAnthropic(
            client,
            connection,
            key,
            modelId,
            messages,
            options,
          );
          if (_chatCancelRequested) {
            throw LlmChatCancelledException();
          }
          final presented = _present(anthropic, options);
          if (presented.thinking.isNotEmpty) {
            yield LlmStreamPart(
              kind: LlmStreamPartKind.thinking,
              delta: presented.thinking,
            );
          }
          if (presented.text.isNotEmpty) {
            yield LlmStreamPart(
              kind: LlmStreamPartKind.answer,
              delta: presented.text,
            );
          }
          return;
        case LlmProviderKind.google:
          final google = await _chatGoogle(
            client,
            connection,
            key,
            modelId,
            messages,
            options,
          );
          if (_chatCancelRequested) {
            throw LlmChatCancelledException();
          }
          final presented = _present(google, options);
          if (presented.thinking.isNotEmpty) {
            yield LlmStreamPart(
              kind: LlmStreamPartKind.thinking,
              delta: presented.thinking,
            );
          }
          if (presented.text.isNotEmpty) {
            yield LlmStreamPart(
              kind: LlmStreamPartKind.answer,
              delta: presented.text,
            );
          }
          return;
        case LlmProviderKind.openai:
        case LlmProviderKind.deepseek:
        case LlmProviderKind.zhipu:
        case LlmProviderKind.openAiCompatible:
          yield* _streamOpenAiCompatible(
            client,
            connection,
            key,
            modelId,
            messages,
            options,
          );
      }
    } on LlmChatCancelledException {
      rethrow;
    } on Object {
      if (_chatCancelRequested) {
        throw LlmChatCancelledException();
      }
      rethrow;
    } finally {
      _closeCancellableChat(client);
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
    final uri = Uri.parse('$root/models')
        .replace(queryParameters: {'key': key});
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

  static final _thinkBlock = RegExp(
    r'<think>[\s\S]*?</think>',
    caseSensitive: false,
  );

  LlmChatResult _present(LlmChatResult result, LlmCompletionOptions options) {
    if (options.thinkingLevel != LlmThinkingLevel.off) return result;
    final text = result.text.replaceAll(_thinkBlock, '').trim();
    if (text == result.text && result.thinking.isEmpty) return result;
    return LlmChatResult(text: text);
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
    if (thinking.enableThinking != null) {
      body['enable_thinking'] = thinking.enableThinking;
    }
  }

  LlmChatResult _parseOpenAiMessage(Map<dynamic, dynamic> message) {
    final thinkingRaw =
        message['reasoning_content'] ?? message['reasoning'] ?? '';
    final thinking = thinkingRaw is String ? thinkingRaw : '';
    final content = message['content'];
    final text = content is String ? content : '';
    return LlmChatResult(text: text.trim(), thinking: thinking.trim());
  }

  LlmChatResult _parseAnthropicContent(List<dynamic> blocks) {
    final thinking = StringBuffer();
    final text = StringBuffer();
    for (final block in blocks) {
      if (block is! Map) continue;
      final type = block['type'];
      if (type == 'thinking') {
        final raw = block['thinking'] ?? block['text'];
        if (raw is String && raw.isNotEmpty) thinking.write(raw);
      } else if (type == 'text') {
        final raw = block['text'];
        if (raw is String && raw.isNotEmpty) text.write(raw);
      }
    }
    return LlmChatResult(
      text: text.toString().trim(),
      thinking: thinking.toString().trim(),
    );
  }

  Future<LlmChatResult> _chatOpenAiCompatible(
    http.Client client,
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
    final response = await client
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
          final parsed = _parseOpenAiMessage(message);
          if (parsed.text.isNotEmpty || parsed.thinking.isNotEmpty) {
            return parsed;
          }
        }
      }
    }
    throw LlmGatewayException('Empty response from model.');
  }

  Stream<LlmStreamPart> _streamOpenAiCompatible(
    http.Client client,
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
    final response = await client.send(request).timeout(_timeout);
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
          final hideThinking = options.thinkingLevel == LlmThinkingLevel.off;
          final reasoning = delta['reasoning_content'] ?? delta['reasoning'];
          if (!hideThinking && reasoning is String && reasoning.isNotEmpty) {
            yield LlmStreamPart(
              kind: LlmStreamPartKind.thinking,
              delta: reasoning,
            );
          }
          final content = delta['content'];
          if (content is String && content.isNotEmpty) {
            yield LlmStreamPart(kind: LlmStreamPartKind.answer, delta: content);
          }
        } on Object {
          continue;
        }
      }
    }
  }

  Future<LlmChatResult> _chatAnthropic(
    http.Client client,
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
    final response = await client
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
      final parsed = _parseAnthropicContent(content);
      if (parsed.text.isNotEmpty || parsed.thinking.isNotEmpty) {
        return parsed;
      }
    }
    throw LlmGatewayException('Empty response from model.');
  }

  Future<LlmChatResult> _chatGoogle(
    http.Client client,
    LlmConnection connection,
    String key,
    String modelId,
    List<LlmChatMessage> messages,
    LlmCompletionOptions options,
  ) async {
    final root = LlmProviderCatalog.resolveApiRoot(connection);
    final uri = Uri.parse('$root/models/$modelId:generateContent')
        .replace(queryParameters: {'key': key});
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
        'includeThoughts': thinking.googleThinkingBudget != 0,
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
    final response = await client
        .post(uri, headers: {'content-type': 'application/json'}, body: body)
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
            final thinking = StringBuffer();
            final answer = StringBuffer();
            for (final part in parts) {
              if (part is! Map) continue;
              final thought = part['thought'];
              if (thought is String && thought.isNotEmpty) {
                thinking.write(thought);
              }
              final text = part['text'];
              if (text is String && text.isNotEmpty) {
                answer.write(text);
              }
            }
            final result = LlmChatResult(
              text: answer.toString().trim(),
              thinking: thinking.toString().trim(),
            );
            if (result.text.isNotEmpty || result.thinking.isNotEmpty) {
              return result;
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
