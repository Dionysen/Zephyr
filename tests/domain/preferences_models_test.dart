import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_background.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/models/window_frame.dart';
import 'package:zephyr/domain/models/workspace_layout.dart';
import 'package:zephyr/domain/models/zephyr_bundled_fonts.dart';

void main() {
  test('clearing a selected font restores the bundled font and path', () {
    final selected = EditorPreferences.defaults.copyWith(
      fontFamily: 'Imported',
      fontPath: '/fonts/imported.ttf',
    );

    final cleared = selected.copyWith(clearFontFamily: true);

    expect(cleared.fontFamily, ZephyrBundledFonts.wenkaiLite);
    expect(cleared.fontPath, isNull);
    expect(cleared.fontSize, selected.fontSize);
  });

  test('background settings clamp opacity and blur and clear to defaults', () {
    final config = EditorBackgroundConfig.defaults.copyWith(
      imagePath: '/images/paper.png',
      fit: EditorBackgroundFit.tile,
      opacity: 2,
      blurSigma: -5,
    );

    expect(config.hasImage, isTrue);
    expect(config.opacity, EditorBackgroundConfig.maxOpacity);
    expect(config.blurSigma, EditorBackgroundConfig.minBlurSigma);
    expect(config.copyWith(opacity: -1, blurSigma: 100).opacity, 0);
    expect(config.copyWith(opacity: -1, blurSigma: 100).blurSigma, 30);
    expect(config.cleared(), EditorBackgroundConfig.defaults);
  });

  test('unknown stored background fit falls back to cover', () {
    expect(
      EditorBackgroundFit.fromStorage('unknown'),
      EditorBackgroundFit.cover,
    );
    for (final fit in EditorBackgroundFit.values) {
      expect(EditorBackgroundFit.fromStorage(fit.storageValue), fit);
    }
  });

  test('workspace layout clamps width and resolves the active library', () {
    final library = const LibraryRegistryEntry(
      id: 'one',
      displayName: 'Writing',
      rootPath: '/writing',
    );
    final layout = WorkspaceLayout.clamped(999).copyWith(
      libraries: [library],
      activeLibraryId: library.id,
      selectedBookId: 'book',
      selectedArticleId: 'article',
      lastLibraryRoot: '/writing',
      lastLibraryBookmark: 'bookmark',
    );

    expect(layout.sidebarWidth, WorkspaceLayout.maxSidebarWidth);
    expect(
      WorkspaceLayout.clamped(0).sidebarWidth,
      WorkspaceLayout.minSidebarWidth,
    );
    expect(layout.activeLibrary, library);
    expect(layout.copyWith(clearActiveLibraryId: true).activeLibrary, isNull);
    final cleared = layout.copyWith(
      clearLastLibraryRoot: true,
      clearSelectedBookId: true,
      clearSelectedArticleId: true,
    );
    expect(cleared.lastLibraryRoot, isNull);
    expect(cleared.lastLibraryBookmark, isNull);
    expect(cleared.selectedBookId, isNull);
    expect(cleared.selectedArticleId, isNull);
  });

  test(
    'library registry rejects invalid records and normalizes legacy fields',
    () {
      expect(LibraryRegistryEntry.fromJson('invalid'), isNull);
      expect(
        LibraryRegistryEntry.fromJson({
          'id': '',
          'displayName': 'A',
          'rootPath': '/a',
        }),
        isNull,
      );
      final entry = LibraryRegistryEntry.fromJson({
        'id': 'one',
        'displayName': 'Writing',
        'rootPath': '/writing',
        'bookmark': '',
        'rank': 2.9,
      })!;
      expect(entry.bookmark, isNull);
      expect(entry.rank, 2);
      expect(LibraryRegistryEntry.fromJson(entry.toJson())!.rank, 2);
      expect(
        entry
            .copyWith(bookmark: 'stored')
            .copyWith(clearBookmark: true)
            .bookmark,
        isNull,
      );
    },
  );

  test('window position requires both coordinates and can be cleared', () {
    expect(WindowFrame.defaults.hasPosition, isFalse);
    expect(WindowFrame.defaults.copyWith(x: 10).hasPosition, isFalse);
    final positioned = WindowFrame.defaults.copyWith(
      x: 10,
      y: 20,
      maximized: true,
    );
    expect(positioned.hasPosition, isTrue);
    expect(
      positioned.copyWith(clearPosition: true),
      const WindowFrame(width: 1280, height: 800, maximized: true),
    );
  });

  test('backup preferences can clear the last automatic backup time', () {
    final saved = BackupPreferences.defaults.copyWith(
      autoBackupEnabled: false,
      lastAutoBackupAt: DateTime.utc(2026, 1, 2),
    );
    final cleared = saved.copyWith(clearLastAutoBackupAt: true);
    expect(cleared.autoBackupEnabled, isFalse);
    expect(cleared.lastAutoBackupAt, isNull);
  });
}
