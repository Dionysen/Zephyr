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
        activeLibraryId: 'lib-1',
        libraries: [
          LibraryRegistryEntry(
            id: 'lib-1',
            displayName: 'Alpha',
            rootPath: '/lib/a',
            bookmark: 'bookmark-data',
            rank: 0,
          ),
          LibraryRegistryEntry(
            id: 'lib-2',
            displayName: 'Beta',
            rootPath: '/lib/b',
            rank: 1,
          ),
        ],
        selectedBookId: 'book-1',
        selectedArticleId: 'article-9',
        expandedVolumesByBook: {
          'book-1': ['vol-a', 'vol-b'],
          'book-2': <String>[],
        },
        sidebarScrollOffsetByBook: {'book-1': 128.5, 'book-2': 0},
        chapterSortByBook: {'book-1': 'titleAsc', 'book-2': 'updatedDesc'},
        booksSheetDualColumn: true,
      ),
    );
    final actual = await repository.load();

    expect(actual.sidebarWidth, 412);
    expect(actual.lastLibraryRoot, '/lib/a');
    expect(actual.lastLibraryBookmark, 'bookmark-data');
    expect(actual.activeLibraryId, 'lib-1');
    expect(actual.libraries, hasLength(2));
    expect(actual.libraries.first.displayName, 'Alpha');
    expect(actual.libraries.last.rootPath, '/lib/b');
    expect(actual.selectedBookId, 'book-1');
    expect(actual.selectedArticleId, 'article-9');
    expect(actual.expandedVolumesByBook, {
      'book-1': ['vol-a', 'vol-b'],
      'book-2': <String>[],
    });
    expect(actual.sidebarScrollOffsetByBook, {'book-1': 128.5, 'book-2': 0});
    expect(actual.chapterSortByBook, {
      'book-1': 'titleAsc',
      'book-2': 'updatedDesc',
    });
    expect(actual.booksSheetDualColumn, isTrue);
  });

  test('migrates lastLibraryRoot into a registry entry', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-layout-migrate-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = WorkspaceLayoutFileStorage(
      directoryProvider: () async => directory,
    );
    await storage.write({
      'sidebarWidth': 300,
      'lastLibraryRoot': '/legacy/MyLib',
      'lastLibraryBookmark': 'bm',
    });
    final actual = await FileWorkspaceLayoutRepository(storage).load();

    expect(actual.libraries, hasLength(1));
    expect(actual.libraries.single.displayName, 'MyLib');
    expect(actual.libraries.single.rootPath, '/legacy/MyLib');
    expect(actual.libraries.single.bookmark, 'bm');
    expect(actual.activeLibraryId, actual.libraries.single.id);
    expect(actual.lastLibraryRoot, '/legacy/MyLib');
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
