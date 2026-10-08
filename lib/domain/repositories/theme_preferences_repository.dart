import '../models/theme_tokens.dart';
import '../models/ui_preferences.dart';

/// Persists the user-owned appearance tokens independently of a library.
abstract interface class ThemePreferencesRepository {
  Future<ThemeTokens> loadTokens();
  Future<UiPreferences> loadUi();
  Future<void> save({required ThemeTokens tokens, required UiPreferences ui});
}
