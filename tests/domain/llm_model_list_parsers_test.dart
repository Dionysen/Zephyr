import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/llm/llm_model_list_parsers.dart';

void main() {
  test('parseOpenAiCompatibleModelList reads data ids', () {
    final models = parseOpenAiCompatibleModelList({
      'data': [
        {'id': 'gpt-4o'},
        {'id': 'gpt-4o-mini', 'name': 'Mini'},
      ],
    });
    expect(models.map((m) => m.id), ['gpt-4o', 'gpt-4o-mini']);
    expect(models.last.displayName, 'Mini');
  });

  test('parseGoogleModelList keeps generateContent models', () {
    final models = parseGoogleModelList({
      'models': [
        {
          'name': 'models/gemini-1.5-flash',
          'displayName': 'Flash',
          'supportedGenerationMethods': ['generateContent'],
        },
        {
          'name': 'models/embedding-001',
          'supportedGenerationMethods': ['embedContent'],
        },
      ],
    });
    expect(models, hasLength(1));
    expect(models.first.id, 'gemini-1.5-flash');
  });
}
