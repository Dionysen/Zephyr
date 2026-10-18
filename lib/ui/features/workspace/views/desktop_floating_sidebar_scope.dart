import 'package:flutter/material.dart';

/// Tracks sidebar popup menus / sheets so the floating sidebar stays open.
class DesktopFloatingSidebarLatch {
  int _holds = 0;

  bool get isHeld => _holds > 0;

  void retain() => _holds++;

  void release() {
    if (_holds > 0) _holds--;
  }
}

/// Provided around the floating sidebar panel (see [DesktopFloatingSidebar]).
class DesktopFloatingSidebarScope extends InheritedWidget {
  const DesktopFloatingSidebarScope({
    super.key,
    required this.latch,
    required this.syncMenuController,
    required super.child,
  });

  final DesktopFloatingSidebarLatch latch;
  final void Function(MenuController controller) syncMenuController;

  static DesktopFloatingSidebarScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DesktopFloatingSidebarScope>();

  /// Keeps the floating sidebar open while an async overlay (e.g. [showMenu]) runs.
  static Future<T?> guardOverlay<T>(
    BuildContext context,
    Future<T?> future,
  ) async {
    final scope = maybeOf(context);
    scope?.latch.retain();
    try {
      return await future;
    } finally {
      scope?.latch.release();
    }
  }

  @override
  bool updateShouldNotify(DesktopFloatingSidebarScope oldWidget) =>
      latch != oldWidget.latch;
}

/// Call from a [MenuAnchor] builder when the sidebar is in floating mode.
void syncFloatingSidebarMenu(BuildContext context, MenuController controller) {
  DesktopFloatingSidebarScope.maybeOf(context)?.syncMenuController(controller);
}

bool focusIsInSidebarPopupMenu(FocusNode? node) {
  final ctx = node?.context;
  if (ctx == null) return false;
  if (ctx.findAncestorWidgetOfExactType<MenuItemButton>() != null) {
    return true;
  }
  if (ctx.findAncestorWidgetOfExactType<SubmenuButton>() != null) {
    return true;
  }
  final route = ModalRoute.of(ctx);
  return route is PopupRoute;
}
