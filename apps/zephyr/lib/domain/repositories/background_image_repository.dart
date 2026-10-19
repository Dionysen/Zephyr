import '../models/editor_background.dart';

/// App-local background image library (import / list / delete).
abstract interface class BackgroundImageRepository {
  Future<List<BackgroundImage>> listImages();

  /// Copies [sourcePath] into the app `backgrounds/` directory.
  Future<BackgroundImage?> importImage(String sourcePath);

  /// Deletes an imported image. Returns false for paths outside the library.
  Future<bool> deleteImage(BackgroundImage image);
}
