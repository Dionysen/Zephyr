/// How a background image fills the writing column.
enum EditorBackgroundFit {
  cover,
  contain,
  fill,
  tile,
  center;

  String get storageValue => name;

  static EditorBackgroundFit fromStorage(String? value) => switch (value) {
    'contain' => EditorBackgroundFit.contain,
    'fill' => EditorBackgroundFit.fill,
    'tile' => EditorBackgroundFit.tile,
    'center' => EditorBackgroundFit.center,
    _ => EditorBackgroundFit.cover,
  };
}

/// Per-mode (light/dark) editor background image settings.
class EditorBackgroundConfig {
  const EditorBackgroundConfig({
    this.imagePath,
    this.fit = EditorBackgroundFit.cover,
    this.opacity = defaultOpacity,
    this.blurSigma = 0,
  });

  static const defaults = EditorBackgroundConfig();

  /// Opacity applied when the user first picks an image (or after clear).
  static const defaultOpacity = 1.0;

  static const minOpacity = 0.0;
  static const maxOpacity = 1.0;
  static const minBlurSigma = 0.0;
  static const maxBlurSigma = 30.0;

  /// Absolute path inside the app `backgrounds/` directory, or null when unset.
  final String? imagePath;
  final EditorBackgroundFit fit;

  /// Image opacity in 0…1 (1 = fully visible).
  final double opacity;

  /// Gaussian blur sigma applied to the image layer only.
  final double blurSigma;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  EditorBackgroundConfig copyWith({
    String? imagePath,
    bool clearImage = false,
    EditorBackgroundFit? fit,
    double? opacity,
    double? blurSigma,
  }) => EditorBackgroundConfig(
    imagePath: clearImage ? null : imagePath ?? this.imagePath,
    fit: fit ?? this.fit,
    opacity: (opacity ?? this.opacity)
        .clamp(minOpacity, maxOpacity)
        .toDouble(),
    blurSigma: (blurSigma ?? this.blurSigma)
        .clamp(minBlurSigma, maxBlurSigma)
        .toDouble(),
  );

  /// Clears the image and resets fit / opacity / blur to defaults.
  EditorBackgroundConfig cleared() => defaults;

  @override
  bool operator ==(Object other) =>
      other is EditorBackgroundConfig &&
      other.imagePath == imagePath &&
      other.fit == fit &&
      other.opacity == opacity &&
      other.blurSigma == blurSigma;

  @override
  int get hashCode => Object.hash(imagePath, fit, opacity, blurSigma);
}

/// An imported background image stored under app support.
class BackgroundImage {
  const BackgroundImage({required this.name, required this.path});

  final String name;
  final String path;
}
