import '../models/theme_tokens.dart';

/// Persists the user-owned appearance tokens independently of a library.
abstract interface class ThemePreferencesRepository {
  Future<ThemeTokens> load();
  Future<void> save(ThemeTokens tokens);
}
