import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/models/library_backup.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import '../repositories/file_workspace_layout_repository.dart';
import '../repositories/purewriter_writing_library_repository.dart';
import 'backup_preferences_file_storage.dart';
import 'cloud_sync_service.dart';
import 'folder_bookmark.dart';
import 'purewriter_database.dart';
import 'workspace_layout_file_storage.dart';

/// Result of a UI-less local (+ optional cloud) backup.
class HeadlessExitBackupResult {
  const HeadlessExitBackupResult({
    required this.didLocal,
    required this.didCloud,
  });

  final bool didLocal;
  final bool didCloud;
}

/// Shared headless backup used by desktop exit worker and mobile WorkManager.
abstract final class HeadlessExitBackup {
  /// Creates one automatic `.pwb`, then uploads it when cloud backup is ready.
  ///
  /// When [expectedRoot] is set, aborts if the remembered library root differs
  /// (desktop exit race). Mobile WorkManager passes null.
  static Future<HeadlessExitBackupResult> run({String? expectedRoot}) async {
    final database = PureWriterDatabase();
    try {
      final layout = FileWorkspaceLayoutRepository(
        WorkspaceLayoutFileStorage(),
      );
      final selected = await _selectedRoot(layout);
      if (selected == null || selected.isEmpty) {
        throw StateError('No library is selected for backup.');
      }
      if (expectedRoot != null &&
          !path.equals(path.absolute(selected), path.absolute(expectedRoot))) {
        throw StateError('The selected library changed before backup started.');
      }

      final localStorage = BackupPreferencesFileStorage();
      final local = await localStorage.load();
      final cloud = CloudSyncService();
      await cloud.load();
      final cloudEnabled = cloud.cloudBackupEnabled && cloud.isSignedIn;
      if (!local.autoBackupEnabled && !cloudEnabled) {
        return const HeadlessExitBackupResult(didLocal: false, didCloud: false);
      }

      await database.openLibrary(selected, createIfMissing: false);
      if (!database.writesAllowed) {
        throw StateError('The selected library is read-only.');
      }
      final library = PureWriterWritingLibraryRepository(database);
      final entry = await library.createBackup(kind: BackupKind.automatic);
      var didCloud = false;
      if (cloudEnabled) {
        await cloud.uploadLocalBackup(library: library, entry: entry);
        didCloud = true;
      }
      if (local.autoBackupEnabled) {
        await localStorage.save(
          local.copyWith(lastAutoBackupAt: DateTime.now()),
        );
      }
      return HeadlessExitBackupResult(didLocal: true, didCloud: didCloud);
    } finally {
      await database.close();
    }
  }

  static Future<String?> _selectedRoot(WorkspaceLayoutRepository layout) async {
    final saved = await layout.load();
    final active = saved.activeLibrary;
    final bookmark = active?.bookmark ?? saved.lastLibraryBookmark;
    if (bookmark != null && Platform.isMacOS) {
      final restored = await FolderBookmarkAccess().restore(bookmark);
      if (restored != null && restored.isNotEmpty) return restored;
    }
    return active?.rootPath ?? saved.lastLibraryRoot;
  }
}
