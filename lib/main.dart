import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'app/zephyr_app.dart';
import 'data/repositories/file_workspace_layout_repository.dart';
import 'data/services/folder_bookmark.dart';
import 'data/services/purewriter_database.dart';
import 'data/services/startup_library.dart';
import 'data/services/workspace_layout_file_storage.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _enableHighRefreshRate();
  await initializeDesktopWindow();
  final database = PureWriterDatabase();
  final layout = FileWorkspaceLayoutRepository(WorkspaceLayoutFileStorage());
  final bookmarks = FolderBookmarkAccess();
  try {
    await openStartupLibrary(
      database: database,
      layout: layout,
      bookmarks: bookmarks,
    );
    runZephyr(database, layoutRepository: layout);
  } on Object catch (error) {
    runZephyr(database, startupError: error, layoutRepository: layout);
  }
}

/// Prefer the display's highest refresh rate (90/120Hz when available).
///
/// Flutter on many Android OEMs otherwise stays at 60Hz even when the system
/// panel supports more. iOS ProMotion is already unlocked via Info.plist.
Future<void> _enableHighRefreshRate() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } on Object {
    // Unsupported API / background activity — keep the system default.
  }
}
