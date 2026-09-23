import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/repositories/editor_preferences_repository.dart';

class EditorPreferencesViewModel extends ChangeNotifier {
  EditorPreferencesViewModel(
    this._preferencesRepository,
    this._fontRepository, {
    Future<void> Function()? onPersisted,
  }) : _onPersisted = onPersisted == null ? null : (() => onPersisted());

  final EditorPreferencesRepository _preferencesRepository;
  final SystemFontRepository _fontRepository;
  final Future<void> Function()? _onPersisted;
  EditorPreferences _preferences = EditorPreferences.defaults;
  List<SystemFont> _systemFonts = const [];
  bool _isLoadingSystemFonts = false;
  Timer? _pendingSave;

  EditorPreferences get preferences => _preferences;
  List<SystemFont> get systemFonts => _systemFonts;
  bool get isLoadingSystemFonts => _isLoadingSystemFonts;

  Future<void> load() async {
    try {
      _preferences = await _preferencesRepository.load();
      await _loadSavedFont();
      notifyListeners();
    } on Object {
      // Formatting preferences must not block a writing session.
    }
  }

  /// Discovers fonts only when the editor settings page needs to display them.
  /// Scanning system font directories during every window startup is costly.
  Future<void> loadSystemFonts() async {
    if (_isLoadingSystemFonts || _systemFonts.isNotEmpty) {
      return;
    }
    _isLoadingSystemFonts = true;
    notifyListeners();
    try {
      _systemFonts = await _fontRepository.listFonts();
    } on Object {
      // Keep the platform default font available if discovery fails.
    } finally {
      _isLoadingSystemFonts = false;
      notifyListeners();
    }
  }

  Future<void> selectFont(SystemFont? font) async {
    if (font == null) {
      _update(_preferences.copyWith(clearFontFamily: true));
      return;
    }
    final family = await _fontRepository.loadFont(font);
    if (family != null) {
      _update(_preferences.copyWith(fontFamily: family, fontPath: font.path));
    }
  }

  void updateFontSize(double value) =>
      _update(_preferences.copyWith(fontSize: value));
  void updateLineHeight(double value) =>
      _update(_preferences.copyWith(lineHeight: value));
  void updateParagraphSpacing(double value) =>
      _update(_preferences.copyWith(paragraphSpacing: value));
  void updateFirstLineIndent(int value) =>
      _update(_preferences.copyWith(firstLineIndent: value));
  void updateMaxContentWidth(double value) =>
      _update(_preferences.copyWith(maxContentWidth: value));

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
    final family = await _fontRepository.loadFont(
      SystemFont(family: '', path: path),
    );
    if (family != null) {
      _preferences = _preferences.copyWith(fontFamily: family);
    }
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
