import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/editor_background.dart';
import '../../../../domain/repositories/background_image_repository.dart';

/// Shared session cache for imported editor background images.
class BackgroundImageLibrary extends ChangeNotifier {
  BackgroundImageLibrary(this._repository);

  final BackgroundImageRepository _repository;
  List<BackgroundImage> _images = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<BackgroundImage> get images => _images;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> ensureLoaded({bool force = false}) async {
    if (_isLoading) {
      return;
    }
    if (_hasLoaded && !force && _images.isNotEmpty) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _images = await _repository.listImages();
      _hasLoaded = true;
    } on Object {
      // Keep an empty list if discovery fails.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BackgroundImage?> importImage(String sourcePath) async {
    final imported = await _repository.importImage(sourcePath);
    if (imported == null) {
      return null;
    }
    try {
      _images = await _repository.listImages();
      _hasLoaded = true;
    } on Object {
      if (!_images.any((image) => image.path == imported.path)) {
        _images = [..._images, imported];
      }
      _hasLoaded = true;
    }
    notifyListeners();
    return imported;
  }

  Future<bool> deleteImage(BackgroundImage image) async {
    final ok = await _repository.deleteImage(image);
    if (!ok) {
      return false;
    }
    try {
      _images = await _repository.listImages();
      _hasLoaded = true;
    } on Object {
      _images = _images.where((item) => item.path != image.path).toList();
    }
    notifyListeners();
    return true;
  }

  /// Whether [path] is missing on disk (used to clear stale selections).
  Future<bool> imageFileMissing(String path) async {
    if (path.isEmpty) return true;
    try {
      return !await File(path).exists();
    } on Object {
      return true;
    }
  }
}
