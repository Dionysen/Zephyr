import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/models/status_bar_mode.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../../domain/repositories/editor_preferences_repository.dart';
import '../../../../domain/repositories/theme_preferences_repository.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(
    this._repository, {
    SystemFontRepository? fontRepository,
    Future<void> Function()? onPersisted,
  }) : _fonts = fontRepository,
       _onPersisted = onPersisted == null ? null : (() => onPersisted());

  final ThemePreferencesRepository _repository;
  final SystemFontRepository? _fonts;
  final Future<void> Function()? _onPersisted;
  ThemeTokens _tokens = ThemeTokens.defaults;
  UiPreferences _ui = UiPreferences.defaults;
  List<SystemFont> _systemFonts = const [];
  bool _isLoadingSystemFonts = false;
  Timer? _pendingSave;

  ThemeTokens get tokens => _tokens;
  UiPreferences get ui => _ui;
  List<SystemFont> get systemFonts => _systemFonts;
  bool get isLoadingSystemFonts => _isLoadingSystemFonts;

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
    if (fonts == null || _isLoadingSystemFonts || _systemFonts.isNotEmpty) {
      return;
    }
    _isLoadingSystemFonts = true;
    notifyListeners();
    try {
      _systemFonts = await fonts.listFonts();
    } on Object {
      // Keep the platform default font available if discovery fails.
    } finally {
      _isLoadingSystemFonts = false;
      notifyListeners();
    }
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
    _ui = UiPreferences.defaults;
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
    try {
      _systemFonts = await fonts.listFonts();
    } on Object {
      // Selection can still proceed with the imported path alone.
    }
    await selectUiFont(imported);
    notifyListeners();
    return _ui.fontPath == imported.path;
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

  void updateStatusBarMode(StatusBarMode value) =>
      _updateUi(_ui.copyWith(statusBarMode: value));

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
    final family = await fonts.loadFont(SystemFont(family: '', path: path));
    if (family != null) {
      _ui = _ui.copyWith(fontFamily: family);
    }
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
