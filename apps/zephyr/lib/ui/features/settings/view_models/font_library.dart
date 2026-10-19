import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/repositories/editor_preferences_repository.dart';

/// Shared session cache for system + imported fonts.
///
/// UI and editor settings both listen to one instance so an import or delete
/// appears in both pickers immediately.
class FontLibrary extends ChangeNotifier {
  FontLibrary(this._repository);

  final SystemFontRepository _repository;
  List<SystemFont> _fonts = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<SystemFont> get fonts => _fonts;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> ensureLoaded({bool force = false}) async {
    if (_isLoading) {
      return;
    }
    if (_hasLoaded && !force && _fonts.isNotEmpty) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _fonts = await _repository.listFonts();
      _hasLoaded = true;
    } on Object {
      // Keep the platform default available if discovery fails.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loadFont(SystemFont font) => _repository.loadFont(font);

  Future<SystemFont?> importFont(String sourcePath) async {
    final imported = await _repository.importFont(sourcePath);
    if (imported == null) {
      return null;
    }
    try {
      _fonts = await _repository.listFonts();
      _hasLoaded = true;
    } on Object {
      // Selection can still proceed with the imported path alone.
      if (!_fonts.any((font) => font.path == imported.path)) {
        _fonts = [..._fonts, imported];
      }
      _hasLoaded = true;
    }
    notifyListeners();
    return imported;
  }

  Future<bool> deleteImportedFont(SystemFont font) async {
    final ok = await _repository.deleteImportedFont(font);
    if (!ok) {
      return false;
    }
    try {
      _fonts = await _repository.listFonts();
      _hasLoaded = true;
    } on Object {
      _fonts = _fonts.where((item) => item.path != font.path).toList();
    }
    notifyListeners();
    return true;
  }

  /// Whether [path] is missing on disk (used to clear stale selections).
  Future<bool> fontFileMissing(String path) async {
    try {
      return !await File(path).exists();
    } on Object {
      return true;
    }
  }
}
