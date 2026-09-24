import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';

/// Opens the single desktop settings window without coupling editor widgets to
/// the platform-specific multi-window plugin.
class SettingsWindowService {
  SettingsWindowService._();

  static final SettingsWindowService instance = SettingsWindowService._();

  static const windowRole = 'settings';
  Future<WindowController>? _windowFuture;

  /// Starts the settings engine before the user requests the window.
  Future<void> prewarm() async {
    if (!_supportsDesktopWindows) return;
    final timeline = developer.TimelineTask()..start('settings.prewarm');
    try {
      await _ensureWindow();
      timeline.instant('settings.window.ready');
    } on Object catch (error, stackTrace) {
      developer.log(
        'Settings window prewarm failed; it will retry when opened.',
        name: 'zephyr.settings',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      timeline.finish();
    }
  }

  Future<bool> open() async {
    if (!_supportsDesktopWindows) return false;
    final timeline = developer.TimelineTask()..start('settings.open');
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final window = await _ensureWindow();
          timeline.instant('settings.window.ready');
          await window.show();
          await DesktopMultiWindow.invokeMethod(window.windowId, 'focus');
          timeline.instant('settings.window.shown');
          return true;
        } on Object catch (error, stackTrace) {
          _windowFuture = null;
          if (attempt == 1) {
            developer.log(
              'Settings window could not be shown.',
              name: 'zephyr.settings',
              error: error,
              stackTrace: stackTrace,
            );
            return false;
          }
        }
      }
      return false;
    } finally {
      timeline.finish();
    }
  }

  bool get _supportsDesktopWindows =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Future<WindowController> _ensureWindow() async {
    final existing = _windowFuture;
    if (existing != null) {
      final window = await existing;
      if (await _isWindowAlive(window.windowId)) {
        return window;
      }
      _windowFuture = null;
    }

    final creating = _createWindow();
    _windowFuture = creating;
    try {
      return await creating;
    } on Object {
      _windowFuture = null;
      rethrow;
    }
  }

  Future<bool> _isWindowAlive(int windowId) async {
    if (windowId == 0) return false;
    final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
    return subWindowIds.contains(windowId);
  }

  Future<WindowController> _createWindow() async {
    final timeline = developer.TimelineTask()..start('settings.createWindow');
    try {
      final window = await DesktopMultiWindow.createWindow(
        jsonEncode(<String, String>{'role': windowRole}),
      );
      timeline.instant('settings.engine.created');
      await window.setFrame(const Rect.fromLTWH(0, 0, 1120, 760));
      await window.center();
      await window.setTitle('Zephyr Settings');
      timeline.instant('settings.window.configured');
      return window;
    } finally {
      timeline.finish();
    }
  }
}
