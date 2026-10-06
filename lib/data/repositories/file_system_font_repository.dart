import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/models/editor_preferences.dart';
import '../../domain/repositories/editor_preferences_repository.dart';
import '../services/system_font_catalog.dart';

/// Desktop font discovery and loading.
///
/// macOS prefers the system font registry so collection fonts (.ttc) and
/// user-installed families appear under their Font Book names. Other desktops
/// scan common font directories, including .ttc/.otc.
class FileSystemFontRepository implements SystemFontRepository {
  FileSystemFontRepository({SystemFontCatalog? catalog, this._directories})
    : _catalog = catalog ?? SystemFontCatalog();

  final SystemFontCatalog _catalog;
  final Iterable<Directory>? _directories;
  final Map<String, String> _loadedFamilies = {};

  @override
  Future<List<SystemFont>> listFonts() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const [];
    }
    final byFamily = <String, SystemFont>{};
    void add(SystemFont font) {
      if (font.family.isEmpty || font.path.isEmpty) {
        return;
      }
      byFamily.putIfAbsent(font.family.toLowerCase(), () => font);
    }

    for (final font in await _catalog.listFonts()) {
      add(font);
    }
    for (final font in await _listDirectoryFonts()) {
      add(font);
    }
    final fonts = byFamily.values.toList()
      ..sort(
        (left, right) =>
            left.family.toLowerCase().compareTo(right.family.toLowerCase()),
      );
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
    final file = File(font.path);
    if (!await file.exists()) {
      return null;
    }
    try {
      final family = 'zephyr-system-${font.path.hashCode}';
      final loader = FontLoader(family)
        ..addFont(file.readAsBytes().then(ByteData.sublistView));
      await loader.load();
      _loadedFamilies[font.path] = family;
      return family;
    } on Object {
      return null;
    }
  }

  Future<List<SystemFont>> _listDirectoryFonts() async {
    final fonts = <SystemFont>[];
    for (final root in _directories ?? _fontDirectories()) {
      if (!await root.exists()) {
        continue;
      }
      try {
        await for (final entity in root.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File || !_isFontFile(entity.path)) {
            continue;
          }
          fonts.add(
            SystemFont(family: _displayName(entity.path), path: entity.path),
          );
        }
      } on Object {
        // A directory may exist but be unreadable in a sandboxed build.
      }
    }
    return fonts;
  }

  Iterable<Directory> _fontDirectories() {
    final home = Platform.environment['HOME'];
    final localAppData = Platform.environment['LOCALAPPDATA'];
    return switch (Platform.operatingSystem) {
      'windows' => [
        Directory(r'C:\Windows\Fonts'),
        if (localAppData != null)
          Directory('$localAppData\\Microsoft\\Windows\\Fonts'),
      ],
      'macos' => [
        Directory('/System/Library/Fonts'),
        Directory('/Library/Fonts'),
        if (home != null) Directory('$home/Library/Fonts'),
      ],
      'linux' => [
        Directory('/usr/share/fonts'),
        Directory('/usr/local/share/fonts'),
        if (home != null) Directory('$home/.local/share/fonts'),
        if (home != null) Directory('$home/.fonts'),
      ],
      _ => const [],
    };
  }
}

bool _isFontFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.ttf') ||
      lower.endsWith('.otf') ||
      lower.endsWith('.ttc') ||
      lower.endsWith('.otc');
}

String _displayName(String path) {
  final fileName = Uri.file(path).pathSegments.last;
  return fileName.replaceFirst(
    RegExp(r'\.(ttf|otf|ttc|otc)$', caseSensitive: false),
    '',
  );
}
