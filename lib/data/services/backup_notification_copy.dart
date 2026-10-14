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

  static String get networkFailureBody => isZh
      ? '无法连接坚果云（网络或 DNS）。请确认网络后重试云备份。'
      : 'Could not reach Nutstore (network or DNS). Check connectivity and retry.';

  static bool isNetworkFailure(Object? error) {
    if (error == null) return false;
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection failed') ||
        text.contains('timed out') ||
        text.contains('connection reset') ||
        text.contains('errno = 7') ||
        text.contains('errno=7');
  }

  static String body({
    required bool success,
    Object? error,
    bool didCloud = false,
    bool didLocal = false,
  }) {
    final zh = isZh;
    if (!success) {
      if (isNetworkFailure(error)) return networkFailureBody;
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
