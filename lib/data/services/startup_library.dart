import '../../domain/models/purewriter_models.dart';
import '../../domain/models/workspace_layout.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import 'folder_bookmark.dart';
import 'purewriter_database.dart';

/// Opens the last writing folder when it is still a valid library, otherwise
/// the application-support default library.
Future<LibraryLocation> openStartupLibrary({
  required PureWriterDatabase database,
  required WorkspaceLayoutRepository layout,
  FolderBookmarkAccess? bookmarks,
}) async {
  final saved = await layout.load();
  final lastRoot = await _restoreLastRoot(saved, bookmarks);
  if (lastRoot != null) {
    try {
      return await database.openLibrary(lastRoot);
    } on LibraryInUseException {
      rethrow;
    } on Object {
      await layout.save(saved.copyWith(clearLastLibraryRoot: true));
    }
  }
  return database.openDefaultLibrary();
}

Future<String?> _restoreLastRoot(
  WorkspaceLayout saved,
  FolderBookmarkAccess? bookmarks,
) async {
  final bookmark = saved.lastLibraryBookmark;
  if (bookmark != null && bookmarks != null) {
    try {
      final restored = await bookmarks.restore(bookmark);
      if (restored != null && restored.isNotEmpty) {
        return restored;
      }
    } on Object {
      // Fall through to the stored path when the bookmark cannot be resolved.
    }
  }
  return saved.lastLibraryRoot;
}
