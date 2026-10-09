import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../../domain/repositories/theme_preferences_repository.dart';
import 'font_library.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(
    this._repository, {
    FontLibrary? fontLibrary,
    Future<void> Function()? onPersisted,
  }) : _fonts = fontLibrary,
       _onPersisted = onPersisted == null ? null : (() => onPersisted()) {
    _fonts?.addListener(_onFontLibraryChanged);
  }

  final ThemePreferencesRepository _repository;
  final FontLibrary? _fonts;
  final Future<void> Function()? _onPersisted;
  ThemeTokens _lightTokens = ThemeTokens.presets[ThemePreset.light]!;
  ThemeTokens _darkTokens = ThemeTokens.defaults;
  AppThemeMode _mode = AppThemeMode.system;
  Brightness _platformBrightness = Brightness.light;
  UiPreferences _ui = UiPreferences.defaults;
  Timer? _pendingSave;

  ThemeTokens get lightTokens => _lightTokens;
  ThemeTokens get darkTokens => _darkTokens;
  AppThemeMode get themeMode => _mode;

  /// Tokens for the currently effective brightness (mode + platform).
  ThemeTokens get tokens => _useDark ? _darkTokens : _lightTokens;

  UiPreferences get ui => _ui;
  List<SystemFont> get systemFonts => _fonts?.fonts ?? const [];
  bool get isLoadingSystemFonts => _fonts?.isLoading ?? false;

  bool get _useDark => switch (_mode) {
    AppThemeMode.dark => true,
    AppThemeMode.light => false,
    AppThemeMode.system => _platformBrightness == Brightness.dark,
  };

  bool get isEffectivelyDark => _useDark;

  Future<void> load({bool loadSavedFont = true}) async {
    try {
      final appearance = await _repository.load();
      _mode = appearance.mode;
      _lightTokens = appearance.lightTokens;
      _darkTokens = appearance.darkTokens;
      _ui = appearance.ui;
      if (loadSavedFont) await _loadSavedFont();
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

  /// Applies [preset] to the color pack for the currently effective mode.
  void applyPreset(ThemePreset preset) {
    final pack = ThemeTokens.presets[preset]!;
    if (_useDark) {
      _darkTokens = pack;
    } else {
      _lightTokens = pack;
    }
    _scheduleSave();
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _scheduleSave();
    notifyListeners();
  }

  /// Resets the active light/dark color pack only; UI chrome prefs are untouched.
  void restoreDefaults() {
    if (_useDark) {
      _darkTokens = ThemeTokens.defaults;
    } else {
      _lightTokens = ThemeTokens.presets[ThemePreset.light]!;
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

  void updateLocalePreference(AppLocalePreference value) =>
      _updateUi(_ui.copyWith(localePreference: value));

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

  @override
  void dispose() {
    _fonts?.removeListener(_onFontLibraryChanged);
    _pendingSave?.cancel();
    super.dispose();
  }
}
