import 'dart:async';

import 'package:flutter/foundation.dart';

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
  ThemeTokens _tokens = ThemeTokens.defaults;
  UiPreferences _ui = UiPreferences.defaults;
  Timer? _pendingSave;

  ThemeTokens get tokens => _tokens;
  UiPreferences get ui => _ui;
  List<SystemFont> get systemFonts => _fonts?.fonts ?? const [];
  bool get isLoadingSystemFonts => _fonts?.isLoading ?? false;

  Future<void> load({bool loadSavedFont = true}) async {
    try {
      _tokens = await _repository.loadTokens();
      _ui = await _repository.loadUi();
      if (loadSavedFont) await _loadSavedFont();
      notifyListeners();
    } on Object {
      // Appearance must never prevent opening a user's writing library.
    }
  }

  /// Discovers fonts only when the appearance settings page needs them.
  Future<void> loadSystemFonts() async {
    final fonts = _fonts;
    if (fonts == null) {
      return;
    }
    await fonts.ensureLoaded();
  }

  void update(ThemeToken token, int value) {
    _tokens = _tokens.withValue(token, value);
    _scheduleSave();
    notifyListeners();
  }

  void applyPreset(ThemePreset preset) {
    _tokens = ThemeTokens.presets[preset]!;
    _scheduleSave();
    notifyListeners();
  }

  void restoreDefaults() {
    _tokens = ThemeTokens.defaults;
    // Keep language; theme restore should not force the UI locale.
    _ui = UiPreferences.defaults.copyWith(
      localePreference: _ui.localePreference,
    );
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

  /// Imports a font file into the app directory, then selects it for UI chrome.
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

  /// Removes an app-imported font and clears UI selection if it was in use.
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
      unawaited(_save(_tokens, _ui));
    });
  }

  Future<void> _save(ThemeTokens tokens, UiPreferences ui) async {
    try {
      await _repository.save(tokens: tokens, ui: ui);
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
