import '../../domain/models/editor_preferences.dart';
import '../../domain/repositories/editor_preferences_repository.dart';
import '../services/editor_preferences_file_storage.dart';

class FileEditorPreferencesRepository implements EditorPreferencesRepository {
  FileEditorPreferencesRepository(this._storage);
  final EditorPreferencesFileStorage _storage;

  @override
  Future<EditorPreferences> load() async {
    final values = await _storage.read();
    if (values == null) return EditorPreferences.defaults;
    return EditorPreferences(
      fontFamily: values['fontFamily'] as String?,
      fontPath: values['fontPath'] as String?,
      fontSize: _double(values, 'fontSize'),
      lineHeight: _double(values, 'lineHeight'),
      paragraphSpacing: _double(values, 'paragraphSpacing'),
      firstLineIndent: _int(values, 'firstLineIndent'),
      maxContentWidth: _double(values, 'maxContentWidth'),
    );
  }

  @override
  Future<void> save(EditorPreferences value) => _storage.write({
    'fontFamily': value.fontFamily,
    'fontPath': value.fontPath,
    'fontSize': value.fontSize,
    'lineHeight': value.lineHeight,
    'paragraphSpacing': value.paragraphSpacing,
    'firstLineIndent': value.firstLineIndent,
    'maxContentWidth': value.maxContentWidth,
  });

  double _double(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! num) throw FormatException('Invalid $key preference.');
    return value.toDouble();
  }

  int _int(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! int) throw FormatException('Invalid $key preference.');
    return value;
  }
}
