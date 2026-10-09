import '../../domain/models/purewriter_models.dart';
import '../../domain/models/workspace_layout.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import 'folder_bookmark.dart';
import 'purewriter_database.dart';

/// Opens the last writing folder when it is still a valid library, otherwise
/// the application-support temporary library so the app can always boot.
///
/// [LibraryInUseException] is rethrown only when both the last folder and the
/// temporary fallback cannot be opened.
Future<LibraryLocation> openStartupLibrary({
  required PureWriterDatabase database,
  required WorkspaceLayoutRepository layout,
  FolderBookmarkAccess? bookmarks,
}) async {
  final saved = await layout.load();
  final lastRoot = await _restoreLastRoot(saved, bookmarks);
  Object? lastError;
  if (lastRoot != null) {
    try {
      return await database.openLibrary(lastRoot);
    } on LibraryInUseException catch (error) {
      lastError = error;
      await layout.save(saved.copyWith(clearLastLibraryRoot: true));
    } on Object {
      await layout.save(saved.copyWith(clearLastLibraryRoot: true));
    }
  }
  try {
    return await database.openDefaultLibrary();
  } on Object {
    if (lastError is LibraryInUseException) {
      throw lastError;
    }
    rethrow;
  }
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
