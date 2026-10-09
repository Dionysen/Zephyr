import '../../domain/models/theme_tokens.dart';
import '../../domain/models/ui_preferences.dart';
import '../../domain/repositories/theme_preferences_repository.dart';
import '../services/theme_file_storage.dart';

class FileThemePreferencesRepository implements ThemePreferencesRepository {
  FileThemePreferencesRepository(this._storage);

  final ThemeFileStorage _storage;

  @override
  Future<ThemeTokens> loadTokens() async {
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
      cursor: _color(
        values,
        'cursor',
        fallback: ThemeTokens.defaults.cursor,
      ),
    );
  }

  @override
  Future<UiPreferences> loadUi() async {
    final values = await _storage.read();
    if (values == null) return UiPreferences.defaults;
    final radius = _double(
      values,
      'uiCornerRadius',
      UiPreferences.defaults.cornerRadius,
    );
    final itemInset = _double(
      values,
      'uiSidebarItemInset',
      UiPreferences.defaults.sidebarItemInset,
    );
    return UiPreferences(
      fontFamily: values['uiFontFamily'] as String?,
      fontPath: values['uiFontPath'] as String?,
      fontSize: _double(values, 'uiFontSize', UiPreferences.defaults.fontSize),
      cornerRadius: radius
          .clamp(UiPreferences.minCornerRadius, UiPreferences.maxCornerRadius)
          .toDouble(),
      showBorders: _bool(
        values,
        'uiShowBorders',
        UiPreferences.defaults.showBorders,
      ),
      sidebarItemInset: itemInset
          .clamp(
            UiPreferences.minSidebarItemInset,
            UiPreferences.maxSidebarItemInset,
          )
          .toDouble(),
    );
  }

  @override
  Future<void> save({
    required ThemeTokens tokens,
    required UiPreferences ui,
  }) => _storage.write({
    'editorSurface': tokens.editorSurface,
    'sidebarSurface': tokens.sidebarSurface,
    'controlSurface': tokens.controlSurface,
    'border': tokens.border,
    'primaryText': tokens.primaryText,
    'mutedText': tokens.mutedText,
    'accent': tokens.accent,
    'cursor': tokens.cursor,
    'uiFontFamily': ui.fontFamily,
    'uiFontPath': ui.fontPath,
    'uiFontSize': ui.fontSize,
    'uiCornerRadius': ui.cornerRadius,
    'uiShowBorders': ui.showBorders,
    'uiSidebarItemInset': ui.sidebarItemInset,
  });

  int _color(Map<String, Object?> values, String key, {int? fallback}) {
    final value = values[key];
    if (value == null && fallback != null) return fallback;
    if (value is! int || value < 0 || value > 0xFFFFFFFF) {
      throw FormatException('Invalid $key token.');
    }
    return value;
  }

  double _double(Map<String, Object?> values, String key, double fallback) {
    final value = values[key];
    if (value == null) return fallback;
    if (value is! num) throw FormatException('Invalid $key preference.');
    return value.toDouble();
  }

  bool _bool(Map<String, Object?> values, String key, bool fallback) {
    final value = values[key];
    if (value == null) return fallback;
    if (value is! bool) throw FormatException('Invalid $key preference.');
    return value;
  }
}
