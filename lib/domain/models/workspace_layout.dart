class WorkspaceLayout {
  const WorkspaceLayout({required this.sidebarWidth});

  static const minSidebarWidth = 220.0;
  static const maxSidebarWidth = 520.0;
  static const defaultSidebarWidth = 334.0;
  static const defaults = WorkspaceLayout(sidebarWidth: defaultSidebarWidth);

  final double sidebarWidth;

  factory WorkspaceLayout.clamped(double width) => WorkspaceLayout(
    sidebarWidth: width.clamp(minSidebarWidth, maxSidebarWidth).toDouble(),
  );
}
