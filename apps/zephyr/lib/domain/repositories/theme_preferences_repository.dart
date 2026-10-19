import '../models/app_theme_mode.dart';
import '../models/theme_color_pack.dart';
import '../models/theme_tokens.dart';
import '../models/ui_preferences.dart';

/// Persisted light/dark theme packs plus chrome UI preferences.
class ThemeAppearance {
  const ThemeAppearance({
    required this.mode,
    required this.lightTokens,
    required this.darkTokens,
    required this.lightPackId,
    required this.darkPackId,
    required this.customPacks,
    required this.ui,
  });

  final AppThemeMode mode;
  final ThemeTokens lightTokens;
  final ThemeTokens darkTokens;
  final String lightPackId;
  final String darkPackId;
  final List<ThemeColorPack> customPacks;
  final UiPreferences ui;
}

/// Persists the user-owned appearance independently of a library.
abstract interface class ThemePreferencesRepository {
  Future<ThemeAppearance> load();
  Future<void> save(ThemeAppearance appearance);
}
