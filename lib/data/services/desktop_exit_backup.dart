import 'dart:io';

import 'desktop_backup_notification.dart';
import 'headless_exit_backup.dart';

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
  ///
  /// Always creates one local automatic `.pwb` first, then uploads that same
  /// file when cloud backup is enabled and Nutstore is connected.
  static Future<void> run(String expectedRoot) async {
    final notification = DesktopBackupNotification();
    try {
      final result = await HeadlessExitBackup.run(expectedRoot: expectedRoot);
      if (!result.didLocal && !result.didCloud) return;
      await notification.show(
        success: true,
        didCloud: result.didCloud,
        didLocal: result.didLocal,
      );
    } on Object catch (error) {
      try {
        await notification.show(success: false, error: error);
      } on Object {
        // The backup error remains the primary failure when notifications are disabled.
      }
      stderr.writeln('Zephyr exit backup failed: $error');
    }
  }
}
