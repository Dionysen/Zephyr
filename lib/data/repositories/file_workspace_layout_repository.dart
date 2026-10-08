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
    final selectedBookId = values['selectedBookId'];
    final selectedArticleId = values['selectedArticleId'];
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
      selectedBookId: selectedBookId is String && selectedBookId.isNotEmpty
          ? selectedBookId
          : null,
      selectedArticleId:
          selectedArticleId is String && selectedArticleId.isNotEmpty
          ? selectedArticleId
          : null,
      expandedVolumesByBook: _stringListMap(values['expandedVolumesByBook']),
      sidebarScrollOffsetByBook: _doubleMap(values['sidebarScrollOffsetByBook']),
    );
  }

  @override
  Future<void> save(WorkspaceLayout layout) => _storage.write({
    'sidebarWidth': layout.sidebarWidth,
    'lastLibraryRoot': layout.lastLibraryRoot,
    'lastLibraryBookmark': layout.lastLibraryBookmark,
    'selectedBookId': layout.selectedBookId,
    'selectedArticleId': layout.selectedArticleId,
    'expandedVolumesByBook': layout.expandedVolumesByBook,
    'sidebarScrollOffsetByBook': layout.sidebarScrollOffsetByBook,
  });

  Map<String, List<String>> _stringListMap(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, List<String>>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is! List) continue;
      out[key] = value.whereType<String>().toList(growable: false);
    }
    return out;
  }

  Map<String, double> _doubleMap(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, double>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is num) {
        out[entry.key.toString()] = value.toDouble();
      }
    }
    return out;
  }
}
