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

  /// Deletes an app-imported font file. Returns false for system fonts or
  /// paths outside the app fonts directory.
  Future<bool> deleteImportedFont(SystemFont font);
}
