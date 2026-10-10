import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/theme_color_pack.dart';
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
        lightPackId: ThemeColorPack.builtInId(ThemePreset.light),
        darkPackId: ThemeColorPack.builtInId(ThemePreset.darkModern),
        customPacks: const [],
        ui: UiPreferences.defaults,
      );
    }

    final customPacks = _readCustomPacks(values);
    final legacy = _readTokens(values, prefix: '');
    final light =
        _readTokens(values, prefix: 'light') ??
        (legacy != null && legacy.isLight
            ? legacy
            : ThemeTokens.presets[ThemePreset.light]!);
    final dark =
        _readTokens(values, prefix: 'dark') ??
        (legacy != null && !legacy.isLight ? legacy : ThemeTokens.defaults);

    return ThemeAppearance(
      mode: AppThemeMode.fromStorage(values['themeMode'] as String?),
      lightTokens: light,
      darkTokens: dark,
      lightPackId: _readPackId(
        values['lightPackId'] as String?,
        tokens: light,
        customPacks: customPacks,
        fallback: ThemeColorPack.builtInId(ThemePreset.light),
      ),
      darkPackId: _readPackId(
        values['darkPackId'] as String?,
        tokens: dark,
        customPacks: customPacks,
        fallback: ThemeColorPack.builtInId(ThemePreset.darkModern),
      ),
      customPacks: customPacks,
      ui: _readUi(values),
    );
  }

  @override
  Future<void> save(ThemeAppearance appearance) => _storage.write({
    'themeMode': appearance.mode.storageValue,
    'lightPackId': appearance.lightPackId,
    'darkPackId': appearance.darkPackId,
    'customPacks': [
      for (final pack in appearance.customPacks)
        {
          'id': pack.id,
          'name': pack.name,
          ..._writeTokens(pack.tokens, prefix: ''),
        },
    ],
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

  List<ThemeColorPack> _readCustomPacks(Map<String, Object?> values) {
    final raw = values['customPacks'];
    if (raw is! List) return const [];
    final packs = <ThemeColorPack>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = entry.map((key, value) => MapEntry(key.toString(), value));
      final id = map['id'];
      final name = map['name'];
      if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
        continue;
      }
      final tokens = _readTokens(map, prefix: '');
      if (tokens == null) continue;
      packs.add(ThemeColorPack(id: id, name: name, tokens: tokens));
    }
    return packs;
  }

  String _readPackId(
    String? stored, {
    required ThemeTokens tokens,
    required List<ThemeColorPack> customPacks,
    required String fallback,
  }) {
    if (stored != null && stored.isNotEmpty) {
      if (_knownPackId(stored, customPacks)) return stored;
    }
    final preset = tokens.preset;
    if (preset != null) return ThemeColorPack.builtInId(preset);
    for (final pack in customPacks) {
      if (pack.tokens == tokens) return pack.id;
    }
    return fallback;
  }

  bool _knownPackId(String id, List<ThemeColorPack> customPacks) {
    for (final preset in ThemePreset.values) {
      if (ThemeColorPack.builtInId(preset) == id) return true;
    }
    return customPacks.any((pack) => pack.id == id);
  }

  ThemeTokens? _readTokens(
    Map<String, Object?> values, {
    required String prefix,
  }) {
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

  Map<String, Object?> _writeTokens(
    ThemeTokens tokens, {
    required String prefix,
  }) {
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
      hideQuickToolbar: _bool(
        values,
        'uiHideQuickToolbar',
        UiPreferences.defaults.hideQuickToolbar,
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
    'uiHideQuickToolbar': ui.hideQuickToolbar,
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
