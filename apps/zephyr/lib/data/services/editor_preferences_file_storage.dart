import 'dart:io';

import 'package:local_json_store/local_json_store.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Zephyr's path and error text for the reusable JSON map file store.
class EditorPreferencesFileStorage extends JsonMapFileStore {
  EditorPreferencesFileStorage({
    Future<Directory> Function()? directoryProvider,
  }) : super(
         directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
         relativePath: path.join('zephyr', 'editor-preferences.json'),
         invalidMessage: 'Invalid editor preferences.',
       );
}
