import 'dart:io';

import 'package:flutter_desktop_notifications/flutter_desktop_notifications.dart';

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
    final zh = Platform.localeName.toLowerCase().startsWith('zh');
    final notifier = DesktopNotifier(appName: 'Zephyr', appId: _appId);
    await notifier.requestPermission();
    await notifier.show(
      NotificationMessage.fromPluginTemplate(
        'zephyr-exit-backup-${DateTime.now().microsecondsSinceEpoch}',
        success
            ? (zh ? 'Zephyr 备份完成' : 'Zephyr backup finished')
            : (zh ? '警告：Zephyr 备份失败' : 'Warning: Zephyr backup failed'),
        success
            ? _successBody(zh: zh, didCloud: didCloud, didLocal: didLocal)
            : (zh
                  ? '请重新打开软件检查备份。${error ?? ''}'
                  : 'Reopen Zephyr to check backups. ${error ?? ''}'),
      ),
    );
  }

  static String _successBody({
    required bool zh,
    required bool didCloud,
    required bool didLocal,
  }) {
    if (didCloud && didLocal) {
      return zh ? '本地和云端备份已完成。' : 'Local and cloud backups are complete.';
    }
    if (didCloud) {
      return zh ? '云端备份已完成。' : 'Cloud backup is complete.';
    }
    return zh ? '本地备份已完成。' : 'Local backup is complete.';
  }
}
