import '../models/llm_settings.dart';

List<LlmModelOption> parseOpenAiCompatibleModelList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! List) return const [];
  final models = <LlmModelOption>[];
  for (final entry in data) {
    if (entry is! Map) continue;
    final id = entry['id'];
    if (id is! String || id.isEmpty) continue;
    final name = entry['name'];
    models.add(
      LlmModelOption(
        id: id,
        displayName: name is String ? name : null,
      ),
    );
  }
  models.sort((a, b) => a.id.compareTo(b.id));
  return models;
}

List<LlmModelOption> parseAnthropicModelList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! List) return const [];
  final models = <LlmModelOption>[];
  for (final entry in data) {
    if (entry is! Map) continue;
    final id = entry['id'];
    if (id is! String || id.isEmpty) continue;
    final display = entry['display_name'];
    models.add(
      LlmModelOption(
        id: id,
        displayName: display is String ? display : null,
      ),
    );
  }
  models.sort((a, b) => a.id.compareTo(b.id));
  return models;
}

List<LlmModelOption> parseGoogleModelList(Map<String, dynamic> json) {
  final modelsRaw = json['models'];
  if (modelsRaw is! List) return const [];
  final models = <LlmModelOption>[];
  for (final entry in modelsRaw) {
    if (entry is! Map) continue;
    final name = entry['name'];
    if (name is! String || !name.startsWith('models/')) continue;
    final id = name.substring('models/'.length);
    if (id.isEmpty) continue;
    final methods = entry['supportedGenerationMethods'];
    if (methods is List && !methods.contains('generateContent')) {
      continue;
    }
    final display = entry['displayName'];
    models.add(
      LlmModelOption(
        id: id,
        displayName: display is String ? display : null,
      ),
    );
  }
  models.sort((a, b) => a.id.compareTo(b.id));
  return models;
}
