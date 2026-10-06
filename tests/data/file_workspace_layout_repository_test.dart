import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_workspace_layout_repository.dart';
import 'package:zephyr/data/services/workspace_layout_file_storage.dart';
import 'package:zephyr/domain/models/workspace_layout.dart';

void main() {
  test('round-trips sidebar width through app-support storage', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-layout-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileWorkspaceLayoutRepository(
      WorkspaceLayoutFileStorage(directoryProvider: () async => directory),
    );

    await repository.save(
      const WorkspaceLayout(
        sidebarWidth: 412,
        lastLibraryRoot: '/lib/a',
        lastLibraryBookmark: 'bookmark-data',
      ),
    );
    final actual = await repository.load();

    expect(actual.sidebarWidth, 412);
    expect(actual.lastLibraryRoot, '/lib/a');
    expect(actual.lastLibraryBookmark, 'bookmark-data');
  });

  test('clamps an out-of-range stored width', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-layout-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = WorkspaceLayoutFileStorage(
      directoryProvider: () async => directory,
    );
    await storage.write({'sidebarWidth': 12});
    final actual = await FileWorkspaceLayoutRepository(storage).load();

    expect(actual.sidebarWidth, WorkspaceLayout.minSidebarWidth);
  });
}
