import 'dart:io';

import 'package:path/path.dart' as path;

import '../../domain/models/library_backup.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import '../repositories/file_workspace_layout_repository.dart';
import '../repositories/purewriter_writing_library_repository.dart';
import 'backup_preferences_file_storage.dart';
import 'cloud_sync_service.dart';
import 'desktop_backup_notification.dart';
import 'folder_bookmark.dart';
import 'purewriter_database.dart';
import 'workspace_layout_file_storage.dart';

/// Launches a detached copy of the desktop app for the last backup.
abstract final class DesktopExitBackup {
  static const argument = '--zephyr-exit-backup';

  static Future<void> launch(String libraryRoot) async {
    await Process.start(Platform.resolvedExecutable, [
      argument,
      libraryRoot,
    ], mode: ProcessStartMode.detached);
  }

  /// Runs without a Flutter frame. Credentials are loaded from secure storage;
  /// they are never passed on the process command line.
  static Future<void> run(String expectedRoot) async {
    final notification = DesktopBackupNotification();
    final database = PureWriterDatabase();
    try {
      final layout = FileWorkspaceLayoutRepository(
        WorkspaceLayoutFileStorage(),
      );
      final selected = await _selectedRoot(layout);
      if (selected == null ||
          !path.equals(path.absolute(selected), path.absolute(expectedRoot))) {
        throw StateError('The selected library changed before backup started.');
      }
      final localStorage = BackupPreferencesFileStorage();
      final local = await localStorage.load();
      final cloud = CloudSyncService();
      await cloud.load();
      // Exit cloud backup runs whenever WebDAV is connected; the auto-sync
      // preference only gates pause/resume sync while the app stays open.
      final cloudEnabled = cloud.isSignedIn;
      if (!local.autoBackupEnabled && !cloudEnabled) return;

      await database.openLibrary(selected, createIfMissing: false);
      if (!database.writesAllowed) {
        throw StateError('The selected library is read-only.');
      }
      final library = PureWriterWritingLibraryRepository(database);
      if (cloudEnabled) {
        // Upload-only: do not pull/merge while the UI process has already exited.
        await cloud.backupNow(library: library, flushPending: () async {});
      } else {
        await library.createBackup(kind: BackupKind.automatic);
      }
      if (local.autoBackupEnabled) {
        await localStorage.save(
          local.copyWith(lastAutoBackupAt: DateTime.now()),
        );
      }
      await notification.show(
        success: true,
        didCloud: cloudEnabled,
        didLocal: local.autoBackupEnabled || cloudEnabled,
      );
    } on Object catch (error) {
      try {
        await notification.show(success: false, error: error);
      } on Object {
        // The backup error remains the primary failure when notifications are disabled.
      }
      stderr.writeln('Zephyr exit backup failed: $error');
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
