import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_workspace_layout_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/data/services/startup_library.dart';
import 'package:zephyr/data/services/workspace_layout_file_storage.dart';
import 'package:zephyr/domain/models/workspace_layout.dart';

void main() {
  test('startup reopens the last writing folder', () async {
    final lastRoot = await Directory.systemTemp.createTemp('zephyr-last-lib-');
    final support = await Directory.systemTemp.createTemp(
      'zephyr-startup-support-',
    );
    addTearDown(() async {
      await lastRoot.delete(recursive: true);
      await support.delete(recursive: true);
    });

    final seed = PureWriterDatabase(supportDirectory: () async => lastRoot);
    await seed.openDefaultLibrary();
    await seed.close();

    final layout = FileWorkspaceLayoutRepository(
      WorkspaceLayoutFileStorage(directoryProvider: () async => support),
    );
    await layout.save(
      WorkspaceLayout(
        sidebarWidth: WorkspaceLayout.defaultSidebarWidth,
        lastLibraryRoot: lastRoot.path,
      ),
    );

    final database = PureWriterDatabase(supportDirectory: () async => support);
    addTearDown(database.close);
    await openStartupLibrary(database: database, layout: layout);

    expect(database.location?.rootPath, lastRoot.path);
  });

  test(
    'startup falls back to the default library when last folder is gone',
    () async {
      final missing = [
        Directory.systemTemp.path,
        'zephyr-missing-library',
      ].join(Platform.pathSeparator);
      final support = await Directory.systemTemp.createTemp(
        'zephyr-startup-support-',
      );
      addTearDown(() => support.delete(recursive: true));

      final layout = FileWorkspaceLayoutRepository(
        WorkspaceLayoutFileStorage(directoryProvider: () async => support),
      );
      await layout.save(
        WorkspaceLayout(
          sidebarWidth: WorkspaceLayout.defaultSidebarWidth,
          lastLibraryRoot: missing,
        ),
      );

      final database = PureWriterDatabase(
        supportDirectory: () async => support,
      );
      addTearDown(database.close);
      await openStartupLibrary(database: database, layout: layout);

      expect(database.location?.rootPath, support.path);
      expect((await layout.load()).lastLibraryRoot, isNull);
    },
  );

  test('startup opens the temporary library when no path is saved', () async {
    final support = await Directory.systemTemp.createTemp(
      'zephyr-startup-temp-',
    );
    addTearDown(() => support.delete(recursive: true));

    final layout = FileWorkspaceLayoutRepository(
      WorkspaceLayoutFileStorage(directoryProvider: () async => support),
    );
    final database = PureWriterDatabase(supportDirectory: () async => support);
    addTearDown(database.close);

    final location = await openStartupLibrary(
      database: database,
      layout: layout,
    );

    expect(location.rootPath, support.path);
    expect(location.schema.writesAllowed, isTrue);
  });
}
