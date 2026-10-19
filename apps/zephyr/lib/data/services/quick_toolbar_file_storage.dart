import 'dart:io';

import 'package:local_json_store/local_json_store.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Zephyr's path and error text for the reusable JSON map file store.
class QuickToolbarFileStorage extends JsonMapFileStore {
  QuickToolbarFileStorage({Future<Directory> Function()? directoryProvider})
    : super(
        directoryProvider: directoryProvider ?? getApplicationSupportDirectory,
        relativePath: path.join('zephyr', 'quick-toolbar.json'),
        invalidMessage: 'Invalid quick toolbar preferences.',
      );
}
