class WorkspaceLayout {
  const WorkspaceLayout({
    required this.sidebarWidth,
    this.lastLibraryRoot,
    this.lastLibraryBookmark,
    this.selectedBookId,
    this.selectedArticleId,
    this.expandedVolumesByBook = const {},
    this.sidebarScrollOffsetByBook = const {},
  });

  static const minSidebarWidth = 220.0;
  static const maxSidebarWidth = 520.0;
  static const defaultSidebarWidth = 334.0;
  static const defaults = WorkspaceLayout(sidebarWidth: defaultSidebarWidth);

  final double sidebarWidth;
  final String? lastLibraryRoot;
  final String? lastLibraryBookmark;
  final String? selectedBookId;
  final String? selectedArticleId;

  /// Book id → expanded volume ids. Missing key means “default: all expanded”.
  /// Empty list means all volumes for that book are collapsed.
  final Map<String, List<String>> expandedVolumesByBook;

  /// Book id → sidebar chapter-list scroll offset.
  final Map<String, double> sidebarScrollOffsetByBook;

  factory WorkspaceLayout.clamped(double width) => WorkspaceLayout(
    sidebarWidth: width.clamp(minSidebarWidth, maxSidebarWidth).toDouble(),
  );

  WorkspaceLayout copyWith({
    double? sidebarWidth,
    String? lastLibraryRoot,
    String? lastLibraryBookmark,
    String? selectedBookId,
    String? selectedArticleId,
    Map<String, List<String>>? expandedVolumesByBook,
    Map<String, double>? sidebarScrollOffsetByBook,
    bool clearLastLibraryRoot = false,
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
  );
}
