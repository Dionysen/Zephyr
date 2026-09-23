import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';

/// Opens the single desktop settings window without coupling editor widgets to
/// the platform-specific multi-window plugin.
class SettingsWindowService {
  static const windowRole = 'settings';

  Future<bool> open() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return false;
    }

    for (final windowId in await DesktopMultiWindow.getAllSubWindowIds()) {
      try {
        final isSettingsWindow = await DesktopMultiWindow.invokeMethod(
          windowId,
          'isSettingsWindow',
        );
        if (isSettingsWindow == true) {
          await DesktopMultiWindow.invokeMethod(windowId, 'activate');
          return true;
        }
      } on Object {
        // A window may be closing while it is being queried.
      }
    }

    final window = await DesktopMultiWindow.createWindow(
      jsonEncode(<String, String>{'role': windowRole}),
    );
    await window.setFrame(const Rect.fromLTWH(0, 0, 1120, 760));
    await window.center();
    await window.setTitle('Zephyr Settings');
    await window.show();
    return true;
  }
}
