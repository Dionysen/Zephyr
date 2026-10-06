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
    ).listFonts();

    expect(fonts.map((font) => font.family).toSet(), {
      'PingFang',
      'SourceHanSerif',
    });
  });
}

class _EmptyCatalog extends SystemFontCatalog {
  @override
  Future<List<SystemFont>> listFonts() async => const [];
}
