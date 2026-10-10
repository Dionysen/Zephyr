/// One remembered PureWriter library folder (display name is Zephyr-only).
class LibraryRegistryEntry {
  const LibraryRegistryEntry({
    required this.id,
    required this.displayName,
    required this.rootPath,
    this.bookmark,
    this.rank = 0,
  });

  final String id;
  final String displayName;
  final String rootPath;
  final String? bookmark;
  final int rank;

  LibraryRegistryEntry copyWith({
    String? displayName,
    String? rootPath,
    String? bookmark,
    int? rank,
    bool clearBookmark = false,
  }) => LibraryRegistryEntry(
    id: id,
    displayName: displayName ?? this.displayName,
    rootPath: rootPath ?? this.rootPath,
    bookmark: clearBookmark ? null : bookmark ?? this.bookmark,
    rank: rank ?? this.rank,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'rootPath': rootPath,
    'bookmark': bookmark,
    'rank': rank,
  };

  static LibraryRegistryEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final displayName = raw['displayName'];
    final rootPath = raw['rootPath'];
    if (id is! String || id.isEmpty) return null;
    if (displayName is! String || displayName.isEmpty) return null;
    if (rootPath is! String || rootPath.isEmpty) return null;
    final bookmark = raw['bookmark'];
    final rank = raw['rank'];
    return LibraryRegistryEntry(
      id: id,
      displayName: displayName,
      rootPath: rootPath,
      bookmark: bookmark is String && bookmark.isNotEmpty ? bookmark : null,
      rank: rank is num ? rank.toInt() : 0,
    );
  }
}

class WorkspaceLayout {
  const WorkspaceLayout({
    required this.sidebarWidth,
    this.lastLibraryRoot,
    this.lastLibraryBookmark,
    this.activeLibraryId,
    this.libraries = const [],
    this.selectedBookId,
    this.selectedArticleId,
    this.expandedVolumesByBook = const {},
    this.sidebarScrollOffsetByBook = const {},
    this.chapterSortByBook = const {},
    this.booksSheetDualColumn = true,
  });

  static const minSidebarWidth = 220.0;
  static const maxSidebarWidth = 520.0;
  static const defaultSidebarWidth = 334.0;
  static const defaults = WorkspaceLayout(sidebarWidth: defaultSidebarWidth);

  final double sidebarWidth;
  final String? lastLibraryRoot;
  final String? lastLibraryBookmark;

  /// Selected [LibraryRegistryEntry.id] when using the multi-library registry.
  final String? activeLibraryId;

  /// Remembered libraries (ordered by [LibraryRegistryEntry.rank]).
  final List<LibraryRegistryEntry> libraries;

  final String? selectedBookId;
  final String? selectedArticleId;

  /// Book id → expanded volume ids. Missing key means “default: all expanded”.
  /// Empty list means all volumes for that book are collapsed.
  final Map<String, List<String>> expandedVolumesByBook;

  /// Book id → sidebar chapter-list scroll offset.
  final Map<String, double> sidebarScrollOffsetByBook;

  /// Book id → [ChapterSortMode.storageId]. Missing key means manual.
  final Map<String, String> chapterSortByBook;

  /// Mobile books sheet two-column grid layout.
  final bool booksSheetDualColumn;

  LibraryRegistryEntry? get activeLibrary {
    final id = activeLibraryId;
    if (id == null) return null;
    for (final entry in libraries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  factory WorkspaceLayout.clamped(double width) => WorkspaceLayout(
    sidebarWidth: width.clamp(minSidebarWidth, maxSidebarWidth).toDouble(),
  );

  WorkspaceLayout copyWith({
    double? sidebarWidth,
    String? lastLibraryRoot,
    String? lastLibraryBookmark,
    String? activeLibraryId,
    List<LibraryRegistryEntry>? libraries,
    String? selectedBookId,
    String? selectedArticleId,
    Map<String, List<String>>? expandedVolumesByBook,
    Map<String, double>? sidebarScrollOffsetByBook,
    Map<String, String>? chapterSortByBook,
    bool? booksSheetDualColumn,
    bool clearLastLibraryRoot = false,
    bool clearActiveLibraryId = false,
    bool clearSelectedBookId = false,
    bool clearSelectedArticleId = false,
  }) => WorkspaceLayout(
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    lastLibraryRoot: clearLastLibraryRoot
        ? null
        : lastLibraryRoot ?? this.lastLibraryRoot,
    lastLibraryBookmark: clearLastLibraryRoot
        ? null
        : lastLibraryBookmark ?? this.lastLibraryBookmark,
    activeLibraryId: clearActiveLibraryId
        ? null
        : activeLibraryId ?? this.activeLibraryId,
    libraries: libraries ?? this.libraries,
    selectedBookId: clearSelectedBookId
        ? null
        : selectedBookId ?? this.selectedBookId,
    selectedArticleId: clearSelectedArticleId
        ? null
        : selectedArticleId ?? this.selectedArticleId,
    expandedVolumesByBook:
        expandedVolumesByBook ?? this.expandedVolumesByBook,
    sidebarScrollOffsetByBook:
        sidebarScrollOffsetByBook ?? this.sidebarScrollOffsetByBook,
    chapterSortByBook: chapterSortByBook ?? this.chapterSortByBook,
    booksSheetDualColumn: booksSheetDualColumn ?? this.booksSheetDualColumn,
  );
}
