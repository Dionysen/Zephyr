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
      divider: _color(
        values,
        'divider',
        fallback: ThemeTokens.defaults.divider,
      ),
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
    final volumeGap = _double(
      values,
      'uiSidebarVolumeGap',
      UiPreferences.defaults.sidebarVolumeGap,
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
      sidebarVolumeGap: volumeGap
          .clamp(
            UiPreferences.minSidebarVolumeGap,
            UiPreferences.maxSidebarVolumeGap,
          )
          .toDouble(),
      immersiveStatusBar: _immersiveStatusBar(values),
      hideStatusBarIcons: _bool(
        values,
        'uiHideStatusBarIcons',
        UiPreferences.defaults.hideStatusBarIcons,
      ),
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
    'divider': tokens.divider,
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
    'uiSidebarVolumeGap': ui.sidebarVolumeGap,
    'uiImmersiveStatusBar': ui.immersiveStatusBar,
    'uiHideStatusBarIcons': ui.hideStatusBarIcons,
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

  /// Prefers [uiImmersiveStatusBar]; migrates legacy [uiStatusBarMode] strings.
  bool _immersiveStatusBar(Map<String, Object?> values) {
    final modern = values['uiImmersiveStatusBar'];
    if (modern is bool) return modern;
    final legacy = values['uiStatusBarMode'];
    if (legacy is String) return legacy == 'immersive';
    return UiPreferences.defaults.immersiveStatusBar;
  }
}
