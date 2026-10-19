import 'package:flutter/material.dart';

/// Reference-counted hold so floating chrome (e.g. desktop sidebar) stays open
/// while a root [Overlay] menu is active.
class ZephyrFloatingOverlayLatch {
  int _holds = 0;

  bool get isHeld => _holds > 0;

  void retain() => _holds++;

  void release() {
    if (_holds > 0) _holds--;
  }
}

class ZephyrFloatingOverlayScope extends InheritedWidget {
  const ZephyrFloatingOverlayScope({
    super.key,
    required this.latch,
    required super.child,
  });

  final ZephyrFloatingOverlayLatch latch;

  static ZephyrFloatingOverlayScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ZephyrFloatingOverlayScope>();

  static void retainOverlay(BuildContext context) {
    maybeOf(context)?.latch.retain();
  }

  static void releaseOverlay(BuildContext context) {
    maybeOf(context)?.latch.release();
  }

  @override
  bool updateShouldNotify(ZephyrFloatingOverlayScope oldWidget) =>
      latch != oldWidget.latch;
}
