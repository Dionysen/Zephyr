class WorkspaceLayout {
  const WorkspaceLayout({
    required this.sidebarWidth,
    this.lastLibraryRoot,
    this.lastLibraryBookmark,
  });

  static const minSidebarWidth = 220.0;
  static const maxSidebarWidth = 520.0;
  static const defaultSidebarWidth = 334.0;
  static const defaults = WorkspaceLayout(sidebarWidth: defaultSidebarWidth);

  final double sidebarWidth;
  final String? lastLibraryRoot;
  final String? lastLibraryBookmark;

  factory WorkspaceLayout.clamped(double width) => WorkspaceLayout(
    sidebarWidth: width.clamp(minSidebarWidth, maxSidebarWidth).toDouble(),
  );

  WorkspaceLayout copyWith({
    double? sidebarWidth,
    String? lastLibraryRoot,
    String? lastLibraryBookmark,
    bool clearLastLibraryRoot = false,
  }) => WorkspaceLayout(
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    lastLibraryRoot: clearLastLibraryRoot
        ? null
        : lastLibraryRoot ?? this.lastLibraryRoot,
    lastLibraryBookmark: clearLastLibraryRoot
        ? null
        : lastLibraryBookmark ?? this.lastLibraryBookmark,
  );
}
