import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/editor_background.dart';
import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/models/theme_color_pack.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../../domain/repositories/theme_preferences_repository.dart';
import 'background_image_library.dart';
import 'font_library.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(
    this._repository, {
    FontLibrary? fontLibrary,
    BackgroundImageLibrary? backgroundImages,
    Future<void> Function()? onPersisted,
  }) : _fonts = fontLibrary,
       _backgrounds = backgroundImages,
       _onPersisted = onPersisted == null ? null : (() => onPersisted()) {
    _fonts?.addListener(_onFontLibraryChanged);
    _backgrounds?.addListener(_onBackgroundLibraryChanged);
  }

  final ThemePreferencesRepository _repository;
  final FontLibrary? _fonts;
  final BackgroundImageLibrary? _backgrounds;
  final Future<void> Function()? _onPersisted;
  ThemeTokens _lightTokens = ThemeTokens.presets[ThemePreset.light]!;
  ThemeTokens _darkTokens = ThemeTokens.defaults;
  String _lightPackId = ThemeColorPack.builtInId(ThemePreset.light);
  String _darkPackId = ThemeColorPack.builtInId(ThemePreset.darkModern);
  List<ThemeColorPack> _customPacks = const [];
  var _nextCustomSeq = 1;
  AppThemeMode _mode = AppThemeMode.system;
  Brightness _platformBrightness = Brightness.light;
  UiPreferences _ui = UiPreferences.defaults;
  Timer? _pendingSave;

  ThemeTokens get lightTokens => _lightTokens;
  ThemeTokens get darkTokens => _darkTokens;
  String get lightPackId => _lightPackId;
  String get darkPackId => _darkPackId;
  AppThemeMode get themeMode => _mode;
  List<ThemeColorPack> get customPacks => List.unmodifiable(_customPacks);

  /// Built-in presets followed by user-saved color packs.
  List<ThemeColorPack> get colorPacks => [
    ...ThemeColorPack.builtIns,
    ..._customPacks,
  ];

  /// Tokens for the currently effective brightness (mode + platform).
  ThemeTokens get tokens => _useDark ? _darkTokens : _lightTokens;

  String get activePackId => _useDark ? _darkPackId : _lightPackId;

  ThemeColorPack? get activePack => packById(activePackId);

  /// True when live tokens differ from the selected pack's stored colors.
  bool get isActivePackCustomized {
    final pack = activePack;
    return pack == null || pack.tokens != tokens;
  }

  UiPreferences get ui => _ui;
  List<SystemFont> get systemFonts => _fonts?.fonts ?? const [];
  bool get isLoadingSystemFonts => _fonts?.isLoading ?? false;
  List<BackgroundImage> get backgroundImages =>
      _backgrounds?.images ?? const [];
  bool get isLoadingBackgroundImages => _backgrounds?.isLoading ?? false;
  bool get hasLoadedBackgroundImages => _backgrounds?.hasLoaded ?? false;

  Future<void> loadBackgroundImages({bool force = false}) =>
      _backgrounds?.ensureLoaded(force: force) ?? Future<void>.value();

  bool get _useDark => switch (_mode) {
    AppThemeMode.dark => true,
    AppThemeMode.light => false,
    AppThemeMode.system => _platformBrightness == Brightness.dark,
  };

  bool get isEffectivelyDark => _useDark;

  ThemeColorPack? packById(String id) {
    for (final pack in ThemeColorPack.builtIns) {
      if (pack.id == id) return pack;
    }
    for (final pack in _customPacks) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// Suggested name for the next saved theme (`主题1` / `Theme 1` via l10n).
  int nextDefaultThemeNumber() {
    final pattern = RegExp(r'^(?:主题|Theme)\s*(\d+)$', caseSensitive: false);
    var max = 0;
    for (final pack in _customPacks) {
      final match = pattern.firstMatch(pack.name.trim());
      if (match != null) {
        max = math.max(max, int.parse(match.group(1)!));
      }
    }
    return max + 1;
  }

  Future<void> load({bool loadSavedFont = true}) async {
    try {
      final appearance = await _repository.load();
      _mode = appearance.mode;
      _lightTokens = appearance.lightTokens;
      _darkTokens = appearance.darkTokens;
      _lightPackId = appearance.lightPackId;
      _darkPackId = appearance.darkPackId;
      _customPacks = List.of(appearance.customPacks);
      _nextCustomSeq = _deriveNextCustomSeq(_customPacks);
      _ui = appearance.ui;
      if (loadSavedFont) await _loadSavedFont();
      await _clearStaleBackgroundSelections();
      notifyListeners();
    } on Object {
      // Appearance must never prevent opening a user's writing library.
    }
  }

  /// Keep system theme mode in sync with the device appearance.
  void syncPlatformBrightness(Brightness brightness) {
    if (_platformBrightness == brightness) return;
    _platformBrightness = brightness;
    if (_mode != AppThemeMode.system) return;
    // Avoid notifyListeners during MaterialApp.builder.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }

  Future<void> loadSystemFonts() async {
    final fonts = _fonts;
    if (fonts == null) {
      return;
    }
    await fonts.ensureLoaded();
  }

  void update(ThemeToken token, int value) {
    if (_useDark) {
      _darkTokens = _darkTokens.withValue(token, value);
    } else {
      _lightTokens = _lightTokens.withValue(token, value);
    }
    _scheduleSave();
    notifyListeners();
  }

  /// Applies a built-in or custom pack to the currently effective mode.
  void applyPack(String packId) {
    final pack = packById(packId);
    if (pack == null) return;
    if (_useDark) {
      _darkTokens = pack.tokens;
      _darkPackId = pack.id;
    } else {
      _lightTokens = pack.tokens;
      _lightPackId = pack.id;
    }
    _scheduleSave();
    notifyListeners();
  }

  void applyPreset(ThemePreset preset) =>
      applyPack(ThemeColorPack.builtInId(preset));

  /// Saves the current mode's colors as a new named theme and selects it.
  void saveCurrentAsTheme(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final pack = _createCustomPack(name: trimmed, tokens: tokens);
    _customPacks = [..._customPacks, pack];
    if (_useDark) {
      _darkPackId = pack.id;
    } else {
      _lightPackId = pack.id;
    }
    _scheduleSave();
    notifyListeners();
  }

  void renameCustomPack(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final index = _customPacks.indexWhere((pack) => pack.id == id);
    if (index < 0) return;
    final packs = List<ThemeColorPack>.of(_customPacks);
    packs[index] = packs[index].copyWith(name: trimmed);
    _customPacks = packs;
    _scheduleSave();
    notifyListeners();
  }

  /// Duplicates a custom pack under [name] without changing the active selection.
  void copyCustomPack(String id, String name) {
    final source = _customPacks.where((pack) => pack.id == id).firstOrNull;
    final trimmed = name.trim();
    if (source == null || trimmed.isEmpty) return;
    final pack = _createCustomPack(name: trimmed, tokens: source.tokens);
    _customPacks = [..._customPacks, pack];
    _scheduleSave();
    notifyListeners();
  }

  void deleteCustomPack(String id) {
    if (!_customPacks.any((pack) => pack.id == id)) return;
    _customPacks = [
      for (final pack in _customPacks)
        if (pack.id != id) pack,
    ];
    if (_lightPackId == id) {
      _lightPackId = ThemeColorPack.builtInId(ThemePreset.light);
      _lightTokens = ThemeTokens.presets[ThemePreset.light]!;
    }
    if (_darkPackId == id) {
      _darkPackId = ThemeColorPack.builtInId(ThemePreset.darkModern);
      _darkTokens = ThemeTokens.defaults;
    }
    _scheduleSave();
    notifyListeners();
  }

  ThemeColorPack _createCustomPack({
    required String name,
    required ThemeTokens tokens,
  }) {
    final id = 'custom_$_nextCustomSeq';
    _nextCustomSeq += 1;
    return ThemeColorPack(id: id, name: name, tokens: tokens);
  }

  void setThemeMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _scheduleSave();
    notifyListeners();
  }

  /// Restores the active mode to its currently selected theme colors.
  void restoreDefaults() {
    final pack = activePack;
    if (pack == null) return;
    if (_useDark) {
      _darkTokens = pack.tokens;
    } else {
      _lightTokens = pack.tokens;
    }
    _scheduleSave();
    notifyListeners();
  }

  Future<void> selectUiFont(SystemFont? font) async {
    final fonts = _fonts;
    if (font == null) {
      _updateUi(_ui.copyWith(clearFontFamily: true));
      return;
    }
    if (fonts == null) return;
    final family = await fonts.loadFont(font);
    if (family != null) {
      _updateUi(_ui.copyWith(fontFamily: family, fontPath: font.path));
    }
  }

  Future<bool> importUiFontFromPath(String sourcePath) async {
    final fonts = _fonts;
    if (fonts == null) return false;
    final imported = await fonts.importFont(sourcePath);
    if (imported == null) {
      return false;
    }
    await selectUiFont(imported);
    return _ui.fontPath == imported.path;
  }

  Future<bool> deleteImportedFont(SystemFont font) async {
    final fonts = _fonts;
    if (fonts == null) return false;
    final ok = await fonts.deleteImportedFont(font);
    if (!ok) {
      return false;
    }
    if (_ui.fontPath == font.path) {
      await selectUiFont(null);
    }
    return true;
  }

  void updateUiFontSize(double value) =>
      _updateUi(_ui.copyWith(fontSize: value));

  void updateCornerRadius(double value) => _updateUi(
    _ui.copyWith(
      cornerRadius: value
          .clamp(UiPreferences.minCornerRadius, UiPreferences.maxCornerRadius)
          .toDouble(),
    ),
  );

  void updateBarCornerRadius(double value) => _updateUi(
    _ui.copyWith(
      barCornerRadius: value
          .clamp(
            UiPreferences.minBarCornerRadius,
            UiPreferences.maxBarCornerRadius,
          )
          .toDouble(),
    ),
  );

  void updateShowBorders(bool value) =>
      _updateUi(_ui.copyWith(showBorders: value));

  void updateSidebarItemInset(double value) => _updateUi(
    _ui.copyWith(
      sidebarItemInset: value
          .clamp(
            UiPreferences.minSidebarItemInset,
            UiPreferences.maxSidebarItemInset,
          )
          .toDouble(),
    ),
  );

  void updateSidebarVolumeGap(double value) => _updateUi(
    _ui.copyWith(
      sidebarVolumeGap: value
          .clamp(
            UiPreferences.minSidebarVolumeGap,
            UiPreferences.maxSidebarVolumeGap,
          )
          .toDouble(),
    ),
  );

  void updateImmersiveStatusBar(bool value) =>
      _updateUi(_ui.copyWith(immersiveStatusBar: value));

  void updateHideStatusBarIcons(bool value) =>
      _updateUi(_ui.copyWith(hideStatusBarIcons: value));

  void updateHideQuickToolbar(bool value) =>
      _updateUi(_ui.copyWith(hideQuickToolbar: value));

  void updateLocalePreference(AppLocalePreference value) =>
      _updateUi(_ui.copyWith(localePreference: value));

  EditorBackgroundConfig editorBackground({required bool dark}) =>
      _ui.editorBackgroundFor(dark: dark);

  void updateEditorBackground({
    required bool dark,
    required EditorBackgroundConfig config,
  }) {
    if (dark) {
      _updateUi(_ui.copyWith(darkEditorBackground: config));
    } else {
      _updateUi(_ui.copyWith(lightEditorBackground: config));
    }
  }

  void clearEditorBackground({required bool dark}) {
    updateEditorBackground(dark: dark, config: EditorBackgroundConfig.defaults);
  }

  Future<BackgroundImage?> importBackgroundImage(String sourcePath) async {
    final library = _backgrounds;
    if (library == null) return null;
    return library.importImage(sourcePath);
  }

  Future<bool> deleteBackgroundImage(BackgroundImage image) async {
    final library = _backgrounds;
    if (library == null) return false;
    final ok = await library.deleteImage(image);
    if (!ok) {
      return false;
    }
    var ui = _ui;
    var changed = false;
    if (ui.lightEditorBackground.imagePath == image.path) {
      ui = ui.copyWith(
        lightEditorBackground: EditorBackgroundConfig.defaults,
      );
      changed = true;
    }
    if (ui.darkEditorBackground.imagePath == image.path) {
      ui = ui.copyWith(darkEditorBackground: EditorBackgroundConfig.defaults);
      changed = true;
    }
    if (changed) {
      _updateUi(ui);
    }
    return true;
  }

  void _updateUi(UiPreferences value) {
    _ui = value;
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_save());
    });
  }

  Future<void> _save() async {
    try {
      await _repository.save(
        ThemeAppearance(
          mode: _mode,
          lightTokens: _lightTokens,
          darkTokens: _darkTokens,
          lightPackId: _lightPackId,
          darkPackId: _darkPackId,
          customPacks: _customPacks,
          ui: _ui,
        ),
      );
      await _onPersisted?.call();
    } on Object {
      // Appearance must never prevent opening a user's writing library.
    }
  }

  Future<void> _loadSavedFont() async {
    final fonts = _fonts;
    final path = _ui.fontPath;
    if (fonts == null || path == null) {
      return;
    }
    if (await fonts.fontFileMissing(path)) {
      _ui = _ui.copyWith(clearFontFamily: true);
      return;
    }
    final family = await fonts.loadFont(SystemFont(family: '', path: path));
    if (family != null) {
      _ui = _ui.copyWith(fontFamily: family);
    }
  }

  void _onFontLibraryChanged() {
    unawaited(_clearStaleSelection());
    notifyListeners();
  }

  Future<void> _clearStaleSelection() async {
    final fonts = _fonts;
    final path = _ui.fontPath;
    if (fonts == null || path == null || !fonts.hasLoaded) {
      return;
    }
    if (await fonts.fontFileMissing(path)) {
      await selectUiFont(null);
    }
  }

  void _onBackgroundLibraryChanged() {
    unawaited(_clearStaleBackgroundSelections());
    notifyListeners();
  }

  Future<void> _clearStaleBackgroundSelections() async {
    final library = _backgrounds;
    if (library == null) return;
    var ui = _ui;
    var changed = false;
    final lightPath = ui.lightEditorBackground.imagePath;
    if (lightPath != null && await library.imageFileMissing(lightPath)) {
      ui = ui.copyWith(
        lightEditorBackground: EditorBackgroundConfig.defaults,
      );
      changed = true;
    }
    final darkPath = ui.darkEditorBackground.imagePath;
    if (darkPath != null && await library.imageFileMissing(darkPath)) {
      ui = ui.copyWith(darkEditorBackground: EditorBackgroundConfig.defaults);
      changed = true;
    }
    if (changed) {
      _updateUi(ui);
    }
  }

  int _deriveNextCustomSeq(List<ThemeColorPack> packs) {
    var max = 0;
    final pattern = RegExp(r'^custom_(\d+)$');
    for (final pack in packs) {
      final match = pattern.firstMatch(pack.id);
      if (match != null) {
        max = math.max(max, int.parse(match.group(1)!));
      }
    }
    return max + 1;
  }

  @override
  void dispose() {
    _fonts?.removeListener(_onFontLibraryChanged);
    _backgrounds?.removeListener(_onBackgroundLibraryChanged);
    _pendingSave?.cancel();
    super.dispose();
  }
}
