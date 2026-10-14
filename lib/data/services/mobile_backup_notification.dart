import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android 13+ notification permission for WorkManager in-progress backup FGS.
abstract final class MobileBackupNotification {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static var _initialized = false;

  static Future<void> ensurePermission() async {
    if (!Platform.isAndroid) return;
    try {
      if (!_initialized) {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await _plugin.initialize(
          settings: const InitializationSettings(android: android),
        );
        _initialized = true;
      }
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    } on Object {
      // Permission is best-effort; the FGS may still run without a visible tray entry.
    }
  }
}
