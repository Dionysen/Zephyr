import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'backup_notification_copy.dart';
import 'headless_exit_backup.dart';
import 'mobile_backup_notification.dart';

/// Schedules leave-time local/cloud backup via Android WorkManager.
///
/// Shows only an in-progress foreground notification while the worker runs;
/// success is silent (notification dismissed with the service).
abstract final class MobileBackgroundBackup {
  static const uniqueName = 'zephyr-exit-backup';
  static const taskName = 'zephyrExitBackup';

  static var _initialized = false;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    await Workmanager().initialize(zephyrBackgroundBackupDispatcher);
    _initialized = true;
  }

  /// Enqueue (or replace) a one-off backup when there is dirty content.
  ///
  /// Returns `true` when a task was registered.
  static Future<bool> scheduleIfNeeded({
    required bool contentDirty,
    required bool cloudBackupEnabled,
    required bool isSignedIn,
    required bool autoBackupEnabled,
    required bool isReadOnly,
  }) async {
    if (!isSupported) return false;
    if (!contentDirty || isReadOnly) return false;
    final wantCloud = cloudBackupEnabled && isSignedIn;
    if (!wantCloud && !autoBackupEnabled) return false;

    await initialize();
    await MobileBackupNotification.ensurePermission();
    final zh = BackupNotificationCopy.isZh;
    await Workmanager().registerOneOffTask(
      uniqueName,
      taskName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: wantCloud ? NetworkType.connected : NetworkType.notRequired,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
      outOfQuotaPolicy: OutOfQuotaPolicy.runAsNonExpeditedWorkRequest,
      expedited: true,
      foregroundServiceConfig: ForegroundServiceConfig(
        notificationTitle: zh ? 'Zephyr 正在备份' : 'Zephyr is backing up',
        notificationText: wantCloud
            ? (zh ? '正在进行云备份…' : 'Cloud backup in progress…')
            : (zh ? '正在创建本地备份…' : 'Creating a local backup…'),
        notificationChannelId: 'zephyr_backup_foreground',
        notificationChannelName: zh ? '备份进行中' : 'Backup in progress',
        notificationId: 71001,
        foregroundServiceType: ForegroundServiceType.dataSync,
      ),
    );
    return true;
  }
}

@pragma('vm:entry-point')
void zephyrBackgroundBackupDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName != MobileBackgroundBackup.taskName) {
      return true;
    }
    try {
      await HeadlessExitBackup.run();
      return true;
    } on Object catch (error, stack) {
      debugPrint('Zephyr background backup failed: $error\n$stack');
      // Returning false triggers WorkManager backoff retry.
      return false;
    }
  });
}
