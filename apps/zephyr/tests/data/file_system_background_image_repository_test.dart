import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_system_background_image_repository.dart';
import 'package:zephyr/domain/models/editor_background.dart';
import 'package:zephyr/ui/features/settings/view_models/background_image_library.dart';

void main() {
  test('importImage copies into the app backgrounds directory', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-import-bg');
    addTearDown(() => root.delete(recursive: true));
    final importedDir = Directory('${root.path}/backgrounds');
    final source = File('${root.path}/paper.jpg')
      ..writeAsBytesSync(List<int>.generate(64, (i) => i));

    final repository = FileSystemBackgroundImageRepository(
      backgroundsDirectory: () async => importedDir,
    );

    final imported = await repository.importImage(source.path);
    expect(imported, isNotNull);
    expect(imported!.name, 'paper.jpg');
    expect(imported.path.startsWith(importedDir.path), isTrue);
    expect(File(imported.path).existsSync(), isTrue);

    await source.delete();
    final images = await repository.listImages();
    expect(images.single.path, imported.path);
    expect(images.single.name, 'paper.jpg');
  });

  test('deleteImage removes app copy and refuses outside paths', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-delete-bg');
    addTearDown(() => root.delete(recursive: true));
    final importedDir = Directory('${root.path}/backgrounds');
    final outside = File('${root.path}/outside.png')
      ..writeAsBytesSync(List<int>.generate(32, (i) => i));
    final source = File('${root.path}/grain.webp')
      ..writeAsBytesSync(List<int>.generate(48, (i) => i + 1));

    final repository = FileSystemBackgroundImageRepository(
      backgroundsDirectory: () async => importedDir,
    );

    final imported = await repository.importImage(source.path);
    expect(imported, isNotNull);

    final refused = await repository.deleteImage(
      BackgroundImage(name: 'outside.png', path: outside.path),
    );
    expect(refused, isFalse);
    expect(outside.existsSync(), isTrue);

    final deleted = await repository.deleteImage(imported!);
    expect(deleted, isTrue);
    expect(File(imported.path).existsSync(), isFalse);
    expect(await repository.listImages(), isEmpty);
  });

  test('rejects non-image extensions', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-reject-bg');
    addTearDown(() => root.delete(recursive: true));
    final importedDir = Directory('${root.path}/backgrounds');
    final source = File('${root.path}/notes.txt')
      ..writeAsBytesSync(const [1, 2, 3]);

    final repository = FileSystemBackgroundImageRepository(
      backgroundsDirectory: () async => importedDir,
    );
    expect(await repository.importImage(source.path), isNull);
  });

  test('BackgroundImageLibrary import and delete refresh the list', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-bg-library');
    addTearDown(() => root.delete(recursive: true));
    final importedDir = Directory('${root.path}/backgrounds');
    final source = File('${root.path}/shared.png')
      ..writeAsBytesSync(List<int>.generate(40, (i) => i));

    final library = BackgroundImageLibrary(
      FileSystemBackgroundImageRepository(
        backgroundsDirectory: () async => importedDir,
      ),
    );

    await library.ensureLoaded();
    expect(library.images, isEmpty);

    final imported = await library.importImage(source.path);
    expect(imported, isNotNull);
    expect(library.images.single.path, imported!.path);

    final deleted = await library.deleteImage(imported);
    expect(deleted, isTrue);
    expect(library.images, isEmpty);
    expect(File(imported.path).existsSync(), isFalse);
  });
}
