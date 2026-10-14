import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android-only bridge: early leave hint so Dart can enqueue WorkManager.
abstract final class AndroidLeaveBackup {
  static const _channel = MethodChannel('zephyr/android_leave_backup');

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Called from native [MainActivity.onUserLeaveHint] while the activity is
  /// still interactive (Home / Recents / back-to-leave).
  static void listenForUserLeaving(VoidCallback onLeaving) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'userLeaving') {
        onLeaving();
      }
    });
  }

  static Future<void> clearUserLeavingListener() async {
    if (!isSupported) return;
    _channel.setMethodCallHandler(null);
  }
}
