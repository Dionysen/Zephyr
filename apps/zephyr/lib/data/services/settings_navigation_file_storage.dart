import 'dart:io';

import 'package:local_json_store/local_json_store.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Zephyr's path and error text for the reusable JSON map file store.
class SettingsNavigationFileStorage extends JsonMapFileStore {
  SettingsNavigationFileStorage({
    Future<Directory> Function()? directoryProvider,
  }) : super(
         directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
         relativePath: path.join('zephyr', 'settings-navigation.json'),
         invalidMessage: 'Invalid settings navigation.',
       );
}
