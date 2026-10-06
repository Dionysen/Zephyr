import 'package:flutter/widgets.dart';

import 'app/zephyr_app.dart';
import 'data/repositories/file_workspace_layout_repository.dart';
import 'data/services/folder_bookmark.dart';
import 'data/services/purewriter_database.dart';
import 'data/services/startup_library.dart';
import 'data/services/workspace_layout_file_storage.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
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
