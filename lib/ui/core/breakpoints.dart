/// Shared layout thresholds so workspace and settings do not invent
/// platform-specific shells.
abstract final class ZephyrBreakpoints {
  static const compact = 720.0;

  static bool isCompact(double width) => width < compact;
}
