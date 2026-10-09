/// How the system status bar is presented on mobile.
enum StatusBarMode {
  /// Opaque status bar matching the app surface.
  normal,

  /// Transparent status bar; app content shows through; icons remain.
  transparent,

  /// Icons auto-hide (immersive sticky). Chrome starts below the status band;
  /// reading content may extend into it after the floating top bar hides.
  immersive,
}
