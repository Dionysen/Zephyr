import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/editor_background.dart';
import '../../domain/repositories/background_image_repository.dart';

/// Stores user background images under app support `backgrounds/`.
class FileSystemBackgroundImageRepository
    implements BackgroundImageRepository {
  FileSystemBackgroundImageRepository({
    Future<Directory> Function()? backgroundsDirectory,
  }) : _backgroundsDirectory =
           backgroundsDirectory ?? _defaultBackgroundsDirectory;

  final Future<Directory> Function() _backgroundsDirectory;

  @override
  Future<List<BackgroundImage>> listImages() async {
    final images = <BackgroundImage>[];
    try {
      final root = await _backgroundsDirectory();
      if (!await root.exists()) {
        return images;
      }
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! File || !_isImageFile(entity.path)) {
          continue;
        }
        images.add(
          BackgroundImage(
            name: _displayName(entity.path),
            path: entity.path,
          ),
        );
      }
    } on Object {
      // Support directory may be unavailable in tests or restricted embeds.
    }
    images.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return images;
  }

  @override
  Future<BackgroundImage?> importImage(String sourcePath) async {
    if (!_isImageFile(sourcePath)) {
      return null;
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      return null;
    }

    late final List<int> bytes;
    try {
      bytes = await source.readAsBytes();
    } on Object {
      return null;
    }
    if (bytes.isEmpty) {
      return null;
    }

    // Reject obviously huge files (~25 MB) to keep blur decoding sane.
    if (bytes.length > 25 * 1024 * 1024) {
      return null;
    }

    final dir = await _backgroundsDirectory();
    await dir.create(recursive: true);
    final digest = Object.hashAll(bytes);
    final originalName = p
        .basename(sourcePath)
        .replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final dest = File(p.join(dir.path, '${digest}_$originalName'));
    if (!await dest.exists()) {
      await dest.writeAsBytes(bytes, flush: true);
    }

    return BackgroundImage(
      name: _displayName(dest.path),
      path: dest.path,
    );
  }

  @override
  Future<bool> deleteImage(BackgroundImage image) async {
    if (image.path.isEmpty) {
      return false;
    }
    late final Directory root;
    try {
      root = await _backgroundsDirectory();
    } on Object {
      return false;
    }
    final rootPath = p.normalize(root.absolute.path);
    final imagePath = p.normalize(File(image.path).absolute.path);
    if (imagePath != rootPath && !p.isWithin(rootPath, imagePath)) {
      return false;
    }
    final file = File(imagePath);
    if (!await file.exists()) {
      return true;
    }
    try {
      await file.delete();
      return true;
    } on Object {
      return false;
    }
  }
}

Future<Directory> _defaultBackgroundsDirectory() async {
  final support = await getApplicationSupportDirectory();
  return Directory(p.join(support.path, 'backgrounds'));
}

bool _isImageFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}

String _displayName(String path) {
  var fileName = p.basename(path);
  // Imported copies are stored as `<hash>_<originalName>`.
  fileName = fileName.replaceFirst(RegExp(r'^-?\d+_'), '');
  if (fileName.isEmpty) {
    fileName = p.basename(path);
  }
  return fileName;
}
