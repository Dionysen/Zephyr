import 'dart:io';

import 'package:flutter/services.dart';

/// Best-effort human device label for backup filenames.
Future<String> resolveDeviceLabel({MethodChannel? channel}) async {
  if (Platform.isAndroid) {
    try {
      final name = await (channel ??
              const MethodChannel('zephyr/purewriter_backup'))
          .invokeMethod<String>('getDeviceName');
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    } on Object {
      // Fall through to hostname / OS default.
    }
  }
  try {
    final host = Platform.localHostname.trim();
    if (host.isNotEmpty) return host;
  } on Object {
    // Some sandboxes reject hostname lookup.
  }
  if (Platform.isWindows) return 'Windows';
  if (Platform.isMacOS) return 'macOS';
  if (Platform.isLinux) return 'Linux';
  if (Platform.isIOS) return 'iOS';
  if (Platform.isAndroid) return 'Android';
  return 'device';
}
