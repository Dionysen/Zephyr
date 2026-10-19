import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';

void main() {
  test('sidebar volume expansion round-trips in ZephyrMeta', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-volume-expand-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final database = PureWriterDatabase();
    await database.openLibrary(directory.path, createIfMissing: true);
    addTearDown(database.close);
    final repository = PureWriterWritingLibraryRepository(database);
    final volume = await repository.createCategory(
      folderId: PureWriterDatabase.defaultFolderId,
      name: 'Volume',
    );

    final model = LibraryViewModel(repository);
    addTearDown(model.dispose);
    await model.load();
    model.toggleVolume(volume.id);
    expect(model.isVolumeExpanded(volume.id), isFalse);
    await model.flushPending();

    final reloaded = LibraryViewModel(repository);
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.isVolumeExpanded(volume.id), isFalse);
  });
}
