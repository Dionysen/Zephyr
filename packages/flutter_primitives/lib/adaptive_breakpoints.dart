/// Width thresholds shared by responsive Flutter layouts.
abstract final class AdaptiveBreakpoints {
  static const compact = 720.0;

  static bool isCompact(double width) => width < compact;
}
