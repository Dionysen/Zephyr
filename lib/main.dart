import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'app/zephyr_app.dart';
import 'data/services/purewriter_database.dart';
import 'data/services/settings_window_service.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsWindowId = _settingsWindowId(arguments);
  if (settingsWindowId != null) {
    _initializeSettingsWindow(settingsWindowId);
    runSettingsWindow(settingsWindowId);
    return;
  }
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(720, 520),
        center: true,
        title: 'Zephyr',
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  final database = PureWriterDatabase();
  try {
    await database.openDefaultLibrary();
    runZephyr(database);
  } on Object catch (error) {
    runZephyr(database, startupError: error);
  }
}

void _initializeSettingsWindow(int windowId) {
  DesktopMultiWindow.setMethodHandler((call, _) async {
    switch (call.method) {
      case 'isSettingsWindow':
        return true;
      case 'activate':
        await WindowController.fromWindowId(windowId).show();
        return true;
    }
    return null;
  });
}

int? _settingsWindowId(List<String> arguments) {
  if (arguments.length < 3 || arguments.first != 'multi_window') {
    return null;
  }
  final data = jsonDecode(arguments[2]);
  if (data is! Map || data['role'] != SettingsWindowService.windowRole) {
    return null;
  }
  return int.tryParse(arguments[1]);
}
