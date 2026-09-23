import '../../domain/models/theme_tokens.dart';
import '../../domain/repositories/theme_preferences_repository.dart';
import '../services/theme_file_storage.dart';

class FileThemePreferencesRepository implements ThemePreferencesRepository {
  FileThemePreferencesRepository(this._storage);

  final ThemeFileStorage _storage;

  @override
  Future<ThemeTokens> load() async {
    final values = await _storage.read();
    if (values == null) return ThemeTokens.defaults;
    return ThemeTokens(
      editorSurface: _color(values, 'editorSurface'),
      sidebarSurface: _color(values, 'sidebarSurface'),
      controlSurface: _color(values, 'controlSurface'),
      border: _color(values, 'border'),
      primaryText: _color(values, 'primaryText'),
      mutedText: _color(values, 'mutedText'),
      accent: _color(values, 'accent'),
    );
  }

  @override
  Future<void> save(ThemeTokens tokens) => _storage.write({
    'editorSurface': tokens.editorSurface,
    'sidebarSurface': tokens.sidebarSurface,
    'controlSurface': tokens.controlSurface,
    'border': tokens.border,
    'primaryText': tokens.primaryText,
    'mutedText': tokens.mutedText,
    'accent': tokens.accent,
  });

  int _color(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! int || value < 0 || value > 0xFFFFFFFF) {
      throw FormatException('Invalid $key token.');
    }
    return value;
  }
}
