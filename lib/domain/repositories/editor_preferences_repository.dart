import '../models/editor_preferences.dart';

abstract interface class EditorPreferencesRepository {
  Future<EditorPreferences> load();
  Future<void> save(EditorPreferences preferences);
}

abstract interface class SystemFontRepository {
  Future<List<SystemFont>> listFonts();
  Future<String?> loadFont(SystemFont font);

  /// Copies [sourcePath] into the app fonts directory and returns the durable
  /// font identity. The original file may be deleted afterwards.
  Future<SystemFont?> importFont(String sourcePath);
}
