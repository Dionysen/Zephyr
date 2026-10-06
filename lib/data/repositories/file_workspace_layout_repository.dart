import '../../domain/models/workspace_layout.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import '../services/workspace_layout_file_storage.dart';

class FileWorkspaceLayoutRepository implements WorkspaceLayoutRepository {
  FileWorkspaceLayoutRepository(this._storage);

  final WorkspaceLayoutFileStorage _storage;

  @override
  Future<WorkspaceLayout> load() async {
    final values = await _storage.read();
    if (values == null) {
      return WorkspaceLayout.defaults;
    }
    final width = values['sidebarWidth'];
    final lastRoot = values['lastLibraryRoot'];
    final bookmark = values['lastLibraryBookmark'];
    return WorkspaceLayout(
      sidebarWidth: width is num
          ? WorkspaceLayout.clamped(width.toDouble()).sidebarWidth
          : WorkspaceLayout.defaultSidebarWidth,
      lastLibraryRoot: lastRoot is String && lastRoot.isNotEmpty
          ? lastRoot
          : null,
      lastLibraryBookmark: bookmark is String && bookmark.isNotEmpty
          ? bookmark
          : null,
    );
  }

  @override
  Future<void> save(WorkspaceLayout layout) => _storage.write({
    'sidebarWidth': layout.sidebarWidth,
    'lastLibraryRoot': layout.lastLibraryRoot,
    'lastLibraryBookmark': layout.lastLibraryBookmark,
  });
}
