import '../../domain/models/app_theme_mode.dart';
import '../../domain/models/editor_background.dart';
import '../../domain/models/theme_color_pack.dart';
import '../../domain/models/theme_tokens.dart';
import '../../domain/models/ui_preferences.dart';
import '../../domain/repositories/theme_preferences_repository.dart';
import '../services/theme_file_storage.dart';
import '../services/ui_preferences_platform_defaults.dart';

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
        ui: UiPreferences.defaults.copyWith(
          sidebarItemCornerRadius: defaultSidebarItemCornerRadiusForPlatform(),
        ),
      );
    }

    final customPacks = _readCustomPacks(values);
    final legacy = _readTokens(values, prefix: '');
    var light =
        _readTokens(values, prefix: 'light') ??
        (legacy != null && legacy.isLight
            ? legacy
            : ThemeTokens.presets[ThemePreset.light]!);
    var dark =
        _readTokens(values, prefix: 'dark') ??
        (legacy != null && !legacy.isLight ? legacy : ThemeTokens.defaults);

    final lightPackId = _readPackId(
      values['lightPackId'] as String?,
      tokens: light,
      customPacks: customPacks,
      fallback: ThemeColorPack.builtInId(ThemePreset.light),
    );
    final darkPackId = _readPackId(
      values['darkPackId'] as String?,
      tokens: dark,
      customPacks: customPacks,
      fallback: ThemeColorPack.builtInId(ThemePreset.darkModern),
    );
    light = _migrateBuiltInTokens(light, lightPackId);
    dark = _migrateBuiltInTokens(dark, darkPackId);

    return ThemeAppearance(
      mode: AppThemeMode.fromStorage(values['themeMode'] as String?),
      lightTokens: light,
      darkTokens: dark,
      lightPackId: lightPackId,
      darkPackId: darkPackId,
      customPacks: customPacks,
      ui: _readUi(values),
    );
  }

  /// Soft blue used by all built-ins before Dark Modern polish.
  static const _legacyLightAccent = 0xFF6B9BE8;

  /// First Dark Modern accent (#0078D4) before matching the Sync button blue.
  static const _previousDarkModernAccent = 0xFF0078D4;

  /// Pre-VS Code Dark Modern default dark pack (surfaces + soft accent).
  static const _legacyDarkModern = ThemeTokens(
    editorSurface: 0xFF1E1E1E,
    sidebarSurface: 0xFF171717,
    controlSurface: 0xFF242424,
    border: 0xFF343434,
    divider: 0xFF222222,
    primaryText: 0xFFE8E8E8,
    mutedText: 0xFF858585,
    accent: _legacyLightAccent,
    cursor: 0xFFFFFFFF,
  );

  /// Dark Modern surfaces with the previous #0078D4 accent.
  static const _previousDarkModern = ThemeTokens(
    editorSurface: 0xFF1F1F1F,
    sidebarSurface: 0xFF181818,
    controlSurface: 0xFF313131,
    border: 0xFF2B2B2B,
    divider: 0xFF2B2B2B,
    primaryText: 0xFFCCCCCC,
    mutedText: 0xFF9D9D9D,
    accent: _previousDarkModernAccent,
    cursor: 0xFFFFFFFF,
  );

  /// Refresh unmodified built-in packs after palette updates ship.
  ThemeTokens _migrateBuiltInTokens(ThemeTokens tokens, String packId) {
    final preset = ThemePreset.values
        .where((item) => ThemeColorPack.builtInId(item) == packId)
        .firstOrNull;
    if (preset == null) return tokens;
    final current = ThemeTokens.presets[preset]!;
    if (preset == ThemePreset.darkModern &&
        (tokens == _legacyDarkModern || tokens == _previousDarkModern)) {
      return current;
    }
    // Prior stock accents on an otherwise unmodified built-in pack.
    if ((tokens.accent == _legacyLightAccent ||
            tokens.accent == _previousDarkModernAccent) &&
        tokens.copyWith(accent: current.accent) == current) {
      return current;
    }
    return tokens;
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
    final chatBubbleRadius = _double(
      values,
      'uiChatBubbleCornerRadius',
      UiPreferences.defaults.chatBubbleCornerRadius,
    );
    final itemInset = _double(
      values,
      'uiSidebarItemInset',
      UiPreferences.defaults.sidebarItemInset,
    );
    final sidebarItemRadius = values.containsKey('uiSidebarItemCornerRadius')
        ? _double(
            values,
            'uiSidebarItemCornerRadius',
            defaultSidebarItemCornerRadiusForPlatform(),
          )
        : defaultSidebarItemCornerRadiusForPlatform();
    final volumeGap = _double(
      values,
      'uiSidebarVolumeGap',
      UiPreferences.defaults.sidebarVolumeGap,
    );
    final uiFontPath = values['uiFontPath'] as String?;
    final uiFontFamily = values['uiFontFamily'] as String?;
    return UiPreferences(
      // Null family with no custom path → bundled default (霞鹜文楷).
      fontFamily:
          uiFontFamily ??
          (uiFontPath == null ? UiPreferences.defaults.fontFamily : null),
      fontPath: uiFontPath,
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
      chatBubbleCornerRadius: chatBubbleRadius
          .clamp(
            UiPreferences.minChatBubbleCornerRadius,
            UiPreferences.maxChatBubbleCornerRadius,
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
      sidebarItemCornerRadius: sidebarItemRadius
          .clamp(UiPreferences.minCornerRadius, UiPreferences.maxCornerRadius)
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
      showChapterDetails: _bool(
        values,
        'uiShowChapterDetails',
        UiPreferences.defaults.showChapterDetails,
      ),
      scrollToHideMobileTopBar: _bool(
        values,
        'uiScrollToHideMobileTopBar',
        UiPreferences.defaults.scrollToHideMobileTopBar,
      ),
      openSidebarAfterBookSwitch: _bool(
        values,
        'uiOpenSidebarAfterBookSwitch',
        UiPreferences.defaults.openSidebarAfterBookSwitch,
      ),
      keepScreenOn: _bool(
        values,
        'uiKeepScreenOn',
        UiPreferences.defaults.keepScreenOn,
      ),
      doubleBackToExit: _bool(
        values,
        'uiDoubleBackToExit',
        UiPreferences.defaults.doubleBackToExit,
      ),
      openBookListOnStartup: _bool(
        values,
        'uiOpenBookListOnStartup',
        UiPreferences.defaults.openBookListOnStartup,
      ),
      openSidebarOnStartup: _bool(
        values,
        'uiOpenSidebarOnStartup',
        UiPreferences.defaults.openSidebarOnStartup,
      ),
      desktopFloatingSidebar: _bool(
        values,
        'uiDesktopFloatingSidebar',
        UiPreferences.defaults.desktopFloatingSidebar,
      ),
      editorBackgroundEnabled: _bool(
        values,
        'uiEditorBackgroundEnabled',
        UiPreferences.defaults.editorBackgroundEnabled,
      ),
      aiFeaturesEnabled: _bool(
        values,
        'uiAiFeaturesEnabled',
        UiPreferences.defaults.aiFeaturesEnabled,
      ),
      hideAiAssistantAvatar: _bool(
        values,
        'uiHideAiAssistantAvatar',
        UiPreferences.defaults.hideAiAssistantAvatar,
      ),
      localePreference: AppLocalePreference.fromStorage(
        values['uiLocale'] as String?,
      ),
      mobileToolsOrder: _stringList(values, 'uiMobileToolsOrder'),
      cloudBackupMenuOrder: _stringList(values, 'uiCloudBackupMenuOrder'),
      lightEditorBackground: _readEditorBackground(values, 'light'),
      darkEditorBackground: _readEditorBackground(values, 'dark'),
    );
  }

  Map<String, Object?> _writeUi(UiPreferences ui) => {
    'uiFontFamily': ui.fontFamily,
    'uiFontPath': ui.fontPath,
    'uiFontSize': ui.fontSize,
    'uiCornerRadius': ui.cornerRadius,
    'uiBarCornerRadius': ui.barCornerRadius,
    'uiChatBubbleCornerRadius': ui.chatBubbleCornerRadius,
    'uiShowBorders': ui.showBorders,
    'uiSidebarItemInset': ui.sidebarItemInset,
    'uiSidebarItemCornerRadius': ui.sidebarItemCornerRadius,
    'uiSidebarVolumeGap': ui.sidebarVolumeGap,
    'uiImmersiveStatusBar': ui.immersiveStatusBar,
    'uiHideStatusBarIcons': ui.hideStatusBarIcons,
    'uiHideQuickToolbar': ui.hideQuickToolbar,
    'uiShowChapterDetails': ui.showChapterDetails,
    'uiScrollToHideMobileTopBar': ui.scrollToHideMobileTopBar,
    'uiOpenSidebarAfterBookSwitch': ui.openSidebarAfterBookSwitch,
    'uiKeepScreenOn': ui.keepScreenOn,
    'uiDoubleBackToExit': ui.doubleBackToExit,
    'uiOpenBookListOnStartup': ui.openBookListOnStartup,
    'uiOpenSidebarOnStartup': ui.openSidebarOnStartup,
    'uiDesktopFloatingSidebar': ui.desktopFloatingSidebar,
    'uiEditorBackgroundEnabled': ui.editorBackgroundEnabled,
    'uiAiFeaturesEnabled': ui.aiFeaturesEnabled,
    'uiHideAiAssistantAvatar': ui.hideAiAssistantAvatar,
    'uiLocale': ui.localePreference.storageValue,
    'uiMobileToolsOrder': ui.mobileToolsOrder,
    'uiCloudBackupMenuOrder': ui.cloudBackupMenuOrder,
    ..._writeEditorBackground(ui.lightEditorBackground, 'light'),
    ..._writeEditorBackground(ui.darkEditorBackground, 'dark'),
  };

  EditorBackgroundConfig _readEditorBackground(
    Map<String, Object?> values,
    String mode,
  ) {
    final path = values['ui${_cap(mode)}BgPath'] as String?;
    final opacity = _double(
      values,
      'ui${_cap(mode)}BgOpacity',
      EditorBackgroundConfig.defaultOpacity,
    );
    final blur = _double(
      values,
      'ui${_cap(mode)}BgBlur',
      EditorBackgroundConfig.defaults.blurSigma,
    );
    return EditorBackgroundConfig(
      imagePath: path == null || path.isEmpty ? null : path,
      fit: EditorBackgroundFit.fromStorage(
        values['ui${_cap(mode)}BgFit'] as String?,
      ),
      opacity: opacity
          .clamp(
            EditorBackgroundConfig.minOpacity,
            EditorBackgroundConfig.maxOpacity,
          )
          .toDouble(),
      blurSigma: blur
          .clamp(
            EditorBackgroundConfig.minBlurSigma,
            EditorBackgroundConfig.maxBlurSigma,
          )
          .toDouble(),
    );
  }

  Map<String, Object?> _writeEditorBackground(
    EditorBackgroundConfig config,
    String mode,
  ) => {
    'ui${_cap(mode)}BgPath': config.imagePath,
    'ui${_cap(mode)}BgFit': config.fit.storageValue,
    'ui${_cap(mode)}BgOpacity': config.opacity,
    'ui${_cap(mode)}BgBlur': config.blurSigma,
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

  List<String> _stringList(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value == null) return const [];
    if (value is! List) throw FormatException('Invalid $key preference.');
    return value.whereType<String>().toList(growable: false);
  }

  bool _immersiveStatusBar(Map<String, Object?> values) {
    final modern = values['uiImmersiveStatusBar'];
    if (modern is bool) return modern;
    final legacy = values['uiStatusBarMode'];
    if (legacy is String) return legacy == 'immersive';
    return UiPreferences.defaults.immersiveStatusBar;
  }
}
