import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/models/editor_preferences.dart';
import '../../domain/repositories/editor_preferences_repository.dart';

/// Desktop-only font discovery and loading. Unsupported platforms return an
/// empty catalogue so mobile continues to use its platform text renderer.
class FileSystemFontRepository implements SystemFontRepository {
  final Map<String, String> _loadedFamilies = {};

  @override
  Future<List<SystemFont>> listFonts() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const [];
    }
    final fonts = <SystemFont>[];
    for (final root in _fontDirectories()) {
      if (!await root.exists()) {
        continue;
      }
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }
        final extension = entity.path.toLowerCase();
        if (!extension.endsWith('.ttf') && !extension.endsWith('.otf')) {
          continue;
        }
        final name = entity.uri.pathSegments.last.replaceFirst(
          RegExp(r'\.(ttf|otf)$', caseSensitive: false),
          '',
        );
        fonts.add(SystemFont(family: name, path: entity.path));
      }
    }
    fonts.sort((left, right) => left.family.compareTo(right.family));
    return fonts;
  }

  @override
  Future<String?> loadFont(SystemFont font) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return null;
    }
    final known = _loadedFamilies[font.path];
    if (known != null) {
      return known;
    }
    final family = 'zephyr-system-${font.path.hashCode}';
    final loader = FontLoader(family)
      ..addFont(File(font.path).readAsBytes().then(ByteData.sublistView));
    await loader.load();
    _loadedFamilies[font.path] = family;
    return family;
  }

  Iterable<Directory> _fontDirectories() => switch (Platform.operatingSystem) {
    'windows' => [Directory(r'C:\Windows\Fonts')],
    'macos' => [
      Directory('/System/Library/Fonts'),
      Directory('/Library/Fonts'),
    ],
    'linux' => [
      Directory('/usr/share/fonts'),
      Directory('/usr/local/share/fonts'),
    ],
    _ => const [],
  };
}
