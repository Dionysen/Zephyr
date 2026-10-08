import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_system_font_repository.dart';
import 'package:zephyr/data/services/system_font_catalog.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';

void main() {
  test('discovers ttf, otf, and collection fonts from a directory', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-fonts');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/PingFang.ttc').writeAsBytes(const []);
    await File('${root.path}/SourceHanSerif.otf').writeAsBytes(const []);
    await File('${root.path}/notes.txt').writeAsBytes(const []);

    final fonts = await FileSystemFontRepository(
      catalog: _EmptyCatalog(),
      directories: [root],
      importedFontsDirectory: () async =>
          Directory('${root.path}/imported-empty'),
    ).listFonts();

    expect(fonts.map((font) => font.family).toSet(), {
      'PingFang',
      'SourceHanSerif',
    });
  });

  test('importFont copies into the app fonts directory', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-import-fonts');
    addTearDown(() => root.delete(recursive: true));
    final importedDir = Directory('${root.path}/imported');
    final source = File('${root.path}/SourceHan.ttf');
    await source.writeAsBytes(List<int>.generate(64, (i) => i));

    final repository = FileSystemFontRepository(
      catalog: _EmptyCatalog(),
      directories: const [],
      importedFontsDirectory: () async => importedDir,
    );

    final imported = await repository.importFont(source.path);
    expect(imported, isNotNull);
    expect(imported!.family, 'SourceHan');
    expect(imported.path.startsWith(importedDir.path), isTrue);
    expect(File(imported.path).existsSync(), isTrue);

    // Original may be deleted; the app copy still lists.
    await source.delete();
    final fonts = await repository.listFonts();
    expect(fonts.single.path, imported.path);
    expect(fonts.single.family, 'SourceHan');
  });
}

class _EmptyCatalog extends SystemFontCatalog {
  @override
  Future<List<SystemFont>> listFonts() async => const [];
}
