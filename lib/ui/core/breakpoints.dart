import 'package:flutter_primitives/adaptive_breakpoints.dart';

/// Zephyr's compatibility API for the shared layout threshold.
abstract final class ZephyrBreakpoints {
  static const compact = AdaptiveBreakpoints.compact;

  static bool isCompact(double width) => AdaptiveBreakpoints.isCompact(width);
}
