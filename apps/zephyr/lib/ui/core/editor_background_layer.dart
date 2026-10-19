import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/editor_background.dart';

/// Paints an optional background image (fit / blur / opacity) behind [child].
///
/// The parent surface color shows through wherever the image does not cover
/// or when opacity is below 1. Blur applies only to the image layer.
class EditorBackgroundLayer extends StatelessWidget {
  const EditorBackgroundLayer({
    super.key,
    required this.config,
    required this.child,
  });

  final EditorBackgroundConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = config.imagePath;
    if (path == null || path.isEmpty) {
      return child;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return child;
    }

    // Expand so tile/center paint against the full writing column.
    Widget image = SizedBox.expand(
      child: Image.file(
        file,
        fit: _boxFit(config.fit),
        alignment: Alignment.center,
        repeat: config.fit == EditorBackgroundFit.tile
            ? ImageRepeat.repeat
            : ImageRepeat.noRepeat,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );

    final blur = config.blurSigma;
    if (blur > 0.01) {
      image = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.clamp,
        ),
        child: image,
      );
    }

    final opacity = config.opacity.clamp(0.0, 1.0);
    if (opacity < 0.999) {
      image = Opacity(opacity: opacity, child: image);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: ClipRect(child: image)),
        child,
      ],
    );
  }

  static BoxFit _boxFit(EditorBackgroundFit fit) => switch (fit) {
    EditorBackgroundFit.cover => BoxFit.cover,
    EditorBackgroundFit.contain => BoxFit.contain,
    EditorBackgroundFit.fill => BoxFit.fill,
    EditorBackgroundFit.tile => BoxFit.none,
    EditorBackgroundFit.center => BoxFit.none,
  };
}
