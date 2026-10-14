import 'dart:io';

import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';

import 'backup_notification_copy.dart';

/// Delivers the result after the normal application window has closed.
class DesktopBackupNotification {
  static const _appId = 'io.zephyr.editor';

  Future<void> show({
    required bool success,
    Object? error,
    bool didCloud = false,
    bool didLocal = false,
  }) async {
    if (Platform.isWindows) {
      await WindowsNotification.registerAumid(
        aumid: _appId,
        displayName: 'Zephyr',
      );
    }
    final notifier = DesktopNotifier(appName: 'Zephyr', appId: _appId);
    await notifier.requestPermission();
    await notifier.show(
      NotificationMessage.fromPluginTemplate(
        'zephyr-exit-backup-${DateTime.now().microsecondsSinceEpoch}',
        BackupNotificationCopy.title(success: success),
        BackupNotificationCopy.body(
          success: success,
          error: error,
          didCloud: didCloud,
          didLocal: didLocal,
        ),
      ),
    );
  }
}
