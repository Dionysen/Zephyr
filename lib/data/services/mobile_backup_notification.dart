import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'backup_notification_copy.dart';

/// System notification for mobile leave / background backup results.
class MobileBackupNotification {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static var _initialized = false;

  static const _channelId = 'zephyr_backup';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> show({
    required bool success,
    Object? error,
    bool didCloud = false,
    bool didLocal = false,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _ensureInitialized();
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await iosPlugin?.requestPermissions(alert: true);

      final title = BackupNotificationCopy.title(success: success);
      final body = BackupNotificationCopy.body(
        success: success,
        error: error,
        didCloud: didCloud,
        didLocal: didLocal,
      );
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            BackupNotificationCopy.androidChannelName,
            channelDescription:
                BackupNotificationCopy.androidChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } on Object {
      // Notifications are best-effort while backgrounding.
    }
  }
}
