import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/repositories/editor_preferences_repository.dart';
import '../../settings/view_models/font_library.dart';

class EditorPreferencesViewModel extends ChangeNotifier {
  EditorPreferencesViewModel(
    this._preferencesRepository,
    this._fontLibrary, {
    Future<void> Function()? onPersisted,
  }) : _onPersisted = onPersisted == null ? null : (() => onPersisted()) {
    _fontLibrary.addListener(_onFontLibraryChanged);
  }

  final EditorPreferencesRepository _preferencesRepository;
  final FontLibrary _fontLibrary;
  final Future<void> Function()? _onPersisted;
  EditorPreferences _preferences = EditorPreferences.defaults;
  Timer? _pendingSave;

  EditorPreferences get preferences => _preferences;
  List<SystemFont> get systemFonts => _fontLibrary.fonts;
  bool get isLoadingSystemFonts => _fontLibrary.isLoading;

  Future<void> load({bool loadSavedFont = true}) async {
    try {
      _preferences = await _preferencesRepository.load();
      if (loadSavedFont) await _loadSavedFont();
      notifyListeners();
    } on Object {
      // Formatting preferences must not block a writing session.
    }
  }

  /// Discovers fonts only when the editor settings page needs to display them.
  /// Scanning system font directories during every window startup is costly.
  Future<void> loadSystemFonts() => _fontLibrary.ensureLoaded();

  Future<void> selectFont(SystemFont? font) async {
    if (font == null) {
      _update(_preferences.copyWith(clearFontFamily: true));
      return;
    }
    final family = await _fontLibrary.loadFont(font);
    if (family != null) {
      _update(_preferences.copyWith(fontFamily: family, fontPath: font.path));
    }
  }

  /// Imports a font file into the app directory, then selects it.
  Future<bool> importFontFromPath(String sourcePath) async {
    final imported = await _fontLibrary.importFont(sourcePath);
    if (imported == null) {
      return false;
    }
    await selectFont(imported);
    return _preferences.fontPath == imported.path;
  }

  /// Removes an app-imported font and clears selection if it was in use.
  Future<bool> deleteImportedFont(SystemFont font) async {
    final ok = await _fontLibrary.deleteImportedFont(font);
    if (!ok) {
      return false;
    }
    if (_preferences.fontPath == font.path) {
      await selectFont(null);
    }
    return true;
  }

  void updateFontSize(double value) =>
      _update(_preferences.copyWith(fontSize: value));
  void updateLineHeight(double value) =>
      _update(_preferences.copyWith(lineHeight: value));
  void updateParagraphSpacing(double value) =>
      _update(_preferences.copyWith(paragraphSpacing: value));
  void updateFirstLineIndent(int value) =>
      _update(_preferences.copyWith(firstLineIndent: value));
  void updateMarginLeft(double value) => _update(
    _preferences.copyWith(
      marginLeft: value.clamp(
        EditorPreferences.minMargin,
        EditorPreferences.maxMargin,
      ),
    ),
  );
  void updateMarginRight(double value) => _update(
    _preferences.copyWith(
      marginRight: value.clamp(
        EditorPreferences.minMargin,
        EditorPreferences.maxMargin,
      ),
    ),
  );
  void updateTitleFontSize(double value) => _update(
    _preferences.copyWith(
      titleFontSize: value.clamp(
        EditorPreferences.minTitleFontSize,
        EditorPreferences.maxTitleFontSize,
      ),
    ),
  );
  void updateTitleCentered(bool value) =>
      _update(_preferences.copyWith(titleCentered: value));

  void _update(EditorPreferences value) {
    _preferences = value;
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_save(value));
    });
    notifyListeners();
  }

  Future<void> _save(EditorPreferences value) async {
    try {
      await _preferencesRepository.save(value);
      await _onPersisted?.call();
    } on Object {
      // The in-memory setting remains usable if preferences storage is unavailable.
    }
  }

  Future<void> _loadSavedFont() async {
    final path = _preferences.fontPath;
    if (path == null) {
      return;
    }
    if (await _fontLibrary.fontFileMissing(path)) {
      _preferences = _preferences.copyWith(clearFontFamily: true);
      return;
    }
    final family = await _fontLibrary.loadFont(
      SystemFont(family: '', path: path),
    );
    if (family != null) {
      _preferences = _preferences.copyWith(fontFamily: family);
    }
  }

  void _onFontLibraryChanged() {
    unawaited(_clearStaleSelection());
    notifyListeners();
  }

  Future<void> _clearStaleSelection() async {
    final path = _preferences.fontPath;
    if (path == null || !_fontLibrary.hasLoaded) {
      return;
    }
    if (await _fontLibrary.fontFileMissing(path)) {
      selectFont(null);
    }
  }

  @override
  void dispose() {
    _fontLibrary.removeListener(_onFontLibraryChanged);
    _pendingSave?.cancel();
    super.dispose();
  }
}
