import 'dart:io';

import 'package:flutter/services.dart';

/// Requests all-files access so Zephyr can open PureWriter `App/Room.db` under
/// shared storage (Documents / SD card) on Android 11+.
class AndroidStorageAccess {
  AndroidStorageAccess({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('zephyr/android_storage');

  final MethodChannel _channel;

  Future<bool> hasFullAccess() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('hasFullAccess') ?? false;
  }

  /// Opens the system "All files access" screen for this app when needed.
  Future<void> ensureFullAccess() async {
    if (!Platform.isAndroid) return;
    if (await hasFullAccess()) return;
    await _channel.invokeMethod<void>('requestFullAccess');
  }
}
