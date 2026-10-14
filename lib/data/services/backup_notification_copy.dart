import 'dart:io';

/// Shared title/body for desktop and mobile backup result notifications.
abstract final class BackupNotificationCopy {
  static bool get isZh => Platform.localeName.toLowerCase().startsWith('zh');

  static String title({required bool success}) {
    final zh = isZh;
    if (success) {
      return zh ? 'Zephyr 备份完成' : 'Zephyr backup finished';
    }
    return zh ? '警告：Zephyr 备份失败' : 'Warning: Zephyr backup failed';
  }

  static String body({
    required bool success,
    Object? error,
    bool didCloud = false,
    bool didLocal = false,
  }) {
    final zh = isZh;
    if (!success) {
      return zh
          ? '请重新打开软件检查备份。${error ?? ''}'
          : 'Reopen Zephyr to check backups. ${error ?? ''}';
    }
    if (didCloud && didLocal) {
      return zh ? '本地和云端备份已完成。' : 'Local and cloud backups are complete.';
    }
    if (didCloud) {
      return zh ? '云端备份已完成。' : 'Cloud backup is complete.';
    }
    return zh ? '本地备份已完成。' : 'Local backup is complete.';
  }

  static String get androidChannelName =>
      isZh ? '备份' : 'Backup';

  static String get androidChannelDescription => isZh
      ? '本地与云端自动备份结果'
      : 'Local and cloud automatic backup results';
}
