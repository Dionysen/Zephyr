import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'app/zephyr_app.dart';
import 'data/services/purewriter_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
