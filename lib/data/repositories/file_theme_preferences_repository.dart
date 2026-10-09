import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/theme_tokens.dart';
import '../../domain/models/ui_preferences.dart';
import '../../domain/repositories/theme_preferences_repository.dart';
import '../services/theme_file_storage.dart';

class FileThemePreferencesRepository implements ThemePreferencesRepository {
  FileThemePreferencesRepository(this._storage);

  final ThemeFileStorage _storage;

  @override
  Future<ThemeAppearance> load() async {
    final values = await _storage.read();
    if (values == null) {
      return ThemeAppearance(
        mode: AppThemeMode.system,
        lightTokens: ThemeTokens.presets[ThemePreset.light]!,
        darkTokens: ThemeTokens.defaults,
        ui: UiPreferences.defaults,
      );
    }

    final legacy = _readTokens(values, prefix: '');
    final light = _readTokens(values, prefix: 'light') ??
        (legacy != null && legacy.isLight
            ? legacy
            : ThemeTokens.presets[ThemePreset.light]!);
    final dark = _readTokens(values, prefix: 'dark') ??
        (legacy != null && !legacy.isLight ? legacy : ThemeTokens.defaults);

    return ThemeAppearance(
      mode: AppThemeMode.fromStorage(values['themeMode'] as String?),
      lightTokens: light,
      darkTokens: dark,
      ui: _readUi(values),
    );
  }

  @override
  Future<void> save(ThemeAppearance appearance) => _storage.write({
    'themeMode': appearance.mode.storageValue,
    ..._writeTokens(appearance.lightTokens, prefix: 'light'),
    ..._writeTokens(appearance.darkTokens, prefix: 'dark'),
    // Keep a resolved snapshot for older readers / debugging.
    ..._writeTokens(
      appearance.mode == AppThemeMode.dark
          ? appearance.darkTokens
          : appearance.lightTokens,
      prefix: '',
    ),
    ..._writeUi(appearance.ui),
  });

  ThemeTokens? _readTokens(Map<String, Object?> values, {required String prefix}) {
    String key(String name) => prefix.isEmpty ? name : '$prefix${_cap(name)}';
    if (values[key('editorSurface')] == null) return null;
    try {
      return ThemeTokens(
        editorSurface: _color(values, key('editorSurface')),
        sidebarSurface: _color(values, key('sidebarSurface')),
        controlSurface: _color(values, key('controlSurface')),
        border: _color(values, key('border')),
        divider: _color(
          values,
          key('divider'),
          fallback: ThemeTokens.defaults.divider,
        ),
        primaryText: _color(values, key('primaryText')),
        mutedText: _color(values, key('mutedText')),
        accent: _color(values, key('accent')),
        cursor: _color(
          values,
          key('cursor'),
          fallback: ThemeTokens.defaults.cursor,
        ),
      );
    } on Object {
      return null;
    }
  }

  Map<String, Object?> _writeTokens(ThemeTokens tokens, {required String prefix}) {
    String key(String name) => prefix.isEmpty ? name : '$prefix${_cap(name)}';
    return {
      key('editorSurface'): tokens.editorSurface,
      key('sidebarSurface'): tokens.sidebarSurface,
      key('controlSurface'): tokens.controlSurface,
      key('border'): tokens.border,
      key('divider'): tokens.divider,
      key('primaryText'): tokens.primaryText,
      key('mutedText'): tokens.mutedText,
      key('accent'): tokens.accent,
      key('cursor'): tokens.cursor,
    };
  }

  UiPreferences _readUi(Map<String, Object?> values) {
    final radius = _double(
      values,
      'uiCornerRadius',
      UiPreferences.defaults.cornerRadius,
    );
    final barRadius = _double(
      values,
      'uiBarCornerRadius',
      UiPreferences.defaults.barCornerRadius,
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
      barCornerRadius: barRadius
          .clamp(
            UiPreferences.minBarCornerRadius,
            UiPreferences.maxBarCornerRadius,
          )
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
      localePreference: AppLocalePreference.fromStorage(
        values['uiLocale'] as String?,
      ),
    );
  }

  Map<String, Object?> _writeUi(UiPreferences ui) => {
    'uiFontFamily': ui.fontFamily,
    'uiFontPath': ui.fontPath,
    'uiFontSize': ui.fontSize,
    'uiCornerRadius': ui.cornerRadius,
    'uiBarCornerRadius': ui.barCornerRadius,
    'uiShowBorders': ui.showBorders,
    'uiSidebarItemInset': ui.sidebarItemInset,
    'uiSidebarVolumeGap': ui.sidebarVolumeGap,
    'uiImmersiveStatusBar': ui.immersiveStatusBar,
    'uiHideStatusBarIcons': ui.hideStatusBarIcons,
    'uiLocale': ui.localePreference.storageValue,
  };

  String _cap(String name) =>
      name.isEmpty ? name : '${name[0].toUpperCase()}${name.substring(1)}';

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

  bool _immersiveStatusBar(Map<String, Object?> values) {
    final modern = values['uiImmersiveStatusBar'];
    if (modern is bool) return modern;
    final legacy = values['uiStatusBarMode'];
    if (legacy is String) return legacy == 'immersive';
    return UiPreferences.defaults.immersiveStatusBar;
  }
}
