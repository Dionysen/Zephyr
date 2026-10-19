import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_background.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/repositories/background_image_repository.dart';
import 'package:zephyr/domain/repositories/editor_preferences_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/background_image_library.dart';
import 'package:zephyr/ui/features/settings/view_models/font_library.dart';

void main() {
  test(
    'font library caches a successful scan and can force a refresh',
    () async {
      final repository = _FontRepository();
      final library = FontLibrary(repository);
      addTearDown(library.dispose);

      await library.ensureLoaded();
      await library.ensureLoaded();
      expect(repository.listCalls, 1);
      expect(library.hasLoaded, isTrue);
      expect(library.fonts, [_FontRepository.font]);

      await library.ensureLoaded(force: true);
      expect(repository.listCalls, 2);
    },
  );

  test(
    'font library ignores a concurrent scan and retries after failure',
    () async {
      final repository = _FontRepository();
      final pending = Completer<List<SystemFont>>();
      repository.pendingList = pending;
      final library = FontLibrary(repository);
      addTearDown(library.dispose);

      final load = library.ensureLoaded();
      expect(library.isLoading, isTrue);
      await library.ensureLoaded();
      expect(repository.listCalls, 1);
      pending.completeError(StateError('scan failed'));
      await load;
      expect(library.isLoading, isFalse);
      expect(library.hasLoaded, isFalse);

      repository.pendingList = null;
      await library.ensureLoaded();
      expect(repository.listCalls, 2);
      expect(library.fonts, [_FontRepository.font]);
    },
  );

  test(
    'font import remains available when rescanning fails and delete removes it',
    () async {
      final repository = _FontRepository()..failList = true;
      final library = FontLibrary(repository);
      addTearDown(library.dispose);

      expect(await library.importFont('/source.ttf'), _FontRepository.font);
      expect(library.fonts, [_FontRepository.font]);
      expect(library.hasLoaded, isTrue);

      expect(await library.deleteImportedFont(_FontRepository.font), isTrue);
      expect(library.fonts, isEmpty);
    },
  );

  test(
    'background library caches images and falls back after a failed rescan',
    () async {
      final repository = _BackgroundRepository();
      final library = BackgroundImageLibrary(repository);
      addTearDown(library.dispose);

      await library.ensureLoaded();
      await library.ensureLoaded();
      expect(repository.listCalls, 1);
      expect(library.hasLoaded, isTrue);

      await library.ensureLoaded(force: true);
      expect(repository.listCalls, 2);

      repository.failList = true;
      expect(
        await library.importImage('/source.png'),
        _BackgroundRepository.image,
      );
      expect(library.images.map((image) => image.path), [
        _BackgroundRepository.image.path,
      ]);
      expect(await library.deleteImage(_BackgroundRepository.image), isTrue);
      expect(library.images, isEmpty);
    },
  );

  test('asset libraries report missing files from the filesystem', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-asset-library-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/asset.ttf');
    await file.writeAsString('font');
    final fonts = FontLibrary(_FontRepository());
    final backgrounds = BackgroundImageLibrary(_BackgroundRepository());
    addTearDown(fonts.dispose);
    addTearDown(backgrounds.dispose);

    expect(await fonts.fontFileMissing(file.path), isFalse);
    expect(await backgrounds.imageFileMissing(file.path), isFalse);
    expect(await backgrounds.imageFileMissing(''), isTrue);
    await file.delete();
    expect(await fonts.fontFileMissing(file.path), isTrue);
    expect(await backgrounds.imageFileMissing(file.path), isTrue);
  });
}

class _FontRepository implements SystemFontRepository {
  static const font = SystemFont(
    family: 'Imported',
    path: '/imported.ttf',
    imported: true,
  );
  int listCalls = 0;
  bool failList = false;
  Completer<List<SystemFont>>? pendingList;

  @override
  Future<List<SystemFont>> listFonts() async {
    listCalls++;
    if (pendingList case final pending?) return pending.future;
    if (failList) throw StateError('scan failed');
    return [font];
  }

  @override
  Future<String?> loadFont(SystemFont font) async => font.family;

  @override
  Future<SystemFont?> importFont(String sourcePath) async => font;

  @override
  Future<bool> deleteImportedFont(SystemFont font) async => true;
}

class _BackgroundRepository implements BackgroundImageRepository {
  static const image = BackgroundImage(name: 'Paper', path: '/paper.png');
  int listCalls = 0;
  bool failList = false;

  @override
  Future<List<BackgroundImage>> listImages() async {
    listCalls++;
    if (failList) throw StateError('scan failed');
    return [image];
  }

  @override
  Future<BackgroundImage?> importImage(String sourcePath) async => image;

  @override
  Future<bool> deleteImage(BackgroundImage image) async => true;
}
