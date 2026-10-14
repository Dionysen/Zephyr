import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../domain/models/workspace_layout.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import '../services/workspace_layout_file_storage.dart';

class FileWorkspaceLayoutRepository implements WorkspaceLayoutRepository {
  FileWorkspaceLayoutRepository(this._storage, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final WorkspaceLayoutFileStorage _storage;
  final Uuid _uuid;

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
    final lastLibraryRoot = lastRoot is String && lastRoot.isNotEmpty
        ? lastRoot
        : null;
    final lastLibraryBookmark = bookmark is String && bookmark.isNotEmpty
        ? bookmark
        : null;

    var libraries = _parseLibraries(values['libraries']);
    var activeLibraryId =
        values['activeLibraryId'] is String &&
            (values['activeLibraryId'] as String).isNotEmpty
        ? values['activeLibraryId'] as String
        : null;

    // Migrate pre-registry layouts that only stored lastLibraryRoot.
    if (libraries.isEmpty && lastLibraryRoot != null) {
      final id = _uuid.v4();
      libraries = [
        LibraryRegistryEntry(
          id: id,
          displayName: path.basename(lastLibraryRoot),
          rootPath: lastLibraryRoot,
          bookmark: lastLibraryBookmark,
          rank: 0,
        ),
      ];
      activeLibraryId = id;
    } else if (activeLibraryId != null &&
        libraries.every((entry) => entry.id != activeLibraryId)) {
      activeLibraryId = libraries.isEmpty ? null : libraries.first.id;
    } else if (activeLibraryId == null && libraries.isNotEmpty) {
      // Prefer matching lastLibraryRoot, else first entry.
      activeLibraryId =
          libraries
              .where((entry) => entry.rootPath == lastLibraryRoot)
              .map((entry) => entry.id)
              .firstOrNull ??
          libraries.first.id;
    }

    final active = libraries
        .where((entry) => entry.id == activeLibraryId)
        .firstOrNull;

    // Older layouts may contain several libraries. Keep only the selected
    // directory in app state; their folders on disk are untouched.
    libraries = active == null
        ? const []
        : [
            active.copyWith(
              displayName: path.basename(active.rootPath),
              rank: 0,
            ),
          ];

    return WorkspaceLayout(
      sidebarWidth: width is num
          ? WorkspaceLayout.clamped(width.toDouble()).sidebarWidth
          : WorkspaceLayout.defaultSidebarWidth,
      lastLibraryRoot: active?.rootPath ?? lastLibraryRoot,
      lastLibraryBookmark: active?.bookmark ?? lastLibraryBookmark,
      activeLibraryId: activeLibraryId,
      libraries: libraries,
      selectedBookId: selectedBookId is String && selectedBookId.isNotEmpty
          ? selectedBookId
          : null,
      selectedArticleId:
          selectedArticleId is String && selectedArticleId.isNotEmpty
          ? selectedArticleId
          : null,
      expandedVolumesByBook: _stringListMap(values['expandedVolumesByBook']),
      sidebarScrollOffsetByBook: _doubleMap(
        values['sidebarScrollOffsetByBook'],
      ),
      chapterSortByBook: _stringMap(values['chapterSortByBook']),
      booksSheetDualColumn: values['booksSheetDualColumn'] != false,
    );
  }

  @override
  Future<void> save(WorkspaceLayout layout) => _storage.write({
    'sidebarWidth': layout.sidebarWidth,
    'lastLibraryRoot': layout.lastLibraryRoot,
    'lastLibraryBookmark': layout.lastLibraryBookmark,
    'activeLibraryId': layout.activeLibraryId,
    'libraries': [
      if (layout.activeLibrary case final entry?)
        entry.copyWith(
          displayName: path.basename(entry.rootPath),
          rank: 0,
        ).toJson(),
    ],
    'selectedBookId': layout.selectedBookId,
    'selectedArticleId': layout.selectedArticleId,
    'expandedVolumesByBook': layout.expandedVolumesByBook,
    'sidebarScrollOffsetByBook': layout.sidebarScrollOffsetByBook,
    'chapterSortByBook': layout.chapterSortByBook,
    'booksSheetDualColumn': layout.booksSheetDualColumn,
  });

  List<LibraryRegistryEntry> _parseLibraries(Object? raw) {
    if (raw is! List) return const [];
    final entries = <LibraryRegistryEntry>[];
    for (final item in raw) {
      final entry = LibraryRegistryEntry.fromJson(item);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => a.rank.compareTo(b.rank));
    return List<LibraryRegistryEntry>.unmodifiable(entries);
  }

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

  Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, String>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is String && value.isNotEmpty) {
        out[entry.key.toString()] = value;
      }
    }
    return out;
  }
}
