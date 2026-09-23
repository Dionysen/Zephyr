import '../models/editor_preferences.dart';

abstract interface class EditorPreferencesRepository {
  Future<EditorPreferences> load();
  Future<void> save(EditorPreferences preferences);
}

abstract interface class SystemFontRepository {
  Future<List<SystemFont>> listFonts();
  Future<String?> loadFont(SystemFont font);
}
