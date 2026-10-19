import 'dart:async';

import 'package:flutter/material.dart';

import '../../editor/view_models/library_view_model.dart';
import '../models/workspace_ai_context_selection.dart';
import '../../../core/zephyr_floating_chrome.dart';
import '../../../core/zephyr_floating_overlay_latch.dart';
import '../../../core/zephyr_theme.dart';
import 'desktop_floating_sidebar_scope.dart';
import 'workspace_sidebar.dart';

/// Left-edge hover zone width that reveals the floating sidebar.
const double kDesktopFloatingSidebarEdgeWidth = 20;

/// Desktop overlay sidebar: does not consume horizontal layout space.
class DesktopFloatingSidebar extends StatefulWidget {
  const DesktopFloatingSidebar({
    super.key,
    required this.model,
    required this.open,
    required this.onOpenChanged,
    required this.maxSidebarWidth,
    required this.openLibrary,
    required this.openSettings,
    this.aiContextEnabled = false,
    this.aiContext,
  });

  final LibraryViewModel model;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final double maxSidebarWidth;
  final Future<void> Function() openLibrary;
  final VoidCallback openSettings;
  final bool aiContextEnabled;
  final WorkspaceAiContextSelection? aiContext;

  @override
  State<DesktopFloatingSidebar> createState() => _DesktopFloatingSidebarState();
}

class _DesktopFloatingSidebarState extends State<DesktopFloatingSidebar> {
  var _pointerOnEdge = false;
  var _pointerOnPanel = false;
  Timer? _closeTimer;
  final _panelFocusNode = FocusNode(skipTraversal: true);
  final _latch = DesktopFloatingSidebarLatch();
  final Set<MenuController> _openMenus = {};

  @override
  void dispose() {
    _closeTimer?.cancel();
    _panelFocusNode.dispose();
    super.dispose();
  }

  void _syncMenuController(MenuController controller) {
    if (controller.isOpen) {
      if (_openMenus.add(controller)) _latch.retain();
    } else if (_openMenus.remove(controller)) {
      _latch.release();
    }
  }

  bool _shouldKeepOpen() {
    if (_pointerOnEdge || _pointerOnPanel) return true;
    if (_latch.isHeld) return true;
    if (_panelFocusNode.hasFocus) return true;
    if (focusIsInSidebarPopupMenu(FocusManager.instance.primaryFocus)) {
      return true;
    }
    return false;
  }

  void _setPointerOnEdge(bool value) {
    if (_pointerOnEdge == value) return;
    _pointerOnEdge = value;
    _syncOpen();
  }

  void _setPointerOnPanel(bool value) {
    if (_pointerOnPanel == value) return;
    _pointerOnPanel = value;
    _syncOpen();
  }

  void _syncOpen() {
    if (_shouldKeepOpen()) {
      _closeTimer?.cancel();
      if (!widget.open) widget.onOpenChanged(true);
      return;
    }
    _scheduleClose();
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_shouldKeepOpen()) return;
      if (widget.open) widget.onOpenChanged(false);
    });
  }

  void _collapse() {
    _closeTimer?.cancel();
    _pointerOnEdge = false;
    _pointerOnPanel = false;
    if (widget.open) widget.onOpenChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.model.sidebarWidth;
    final panelWidth = width + SidebarResizeHandle.width;
    final radius = context.zephyrBarBorderRadius;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: kDesktopFloatingSidebarEdgeWidth,
          child: MouseRegion(
            onEnter: (_) => _setPointerOnEdge(true),
            onExit: (_) => _setPointerOnEdge(false),
            child: const SizedBox.expand(),
          ),
        ),
        IgnorePointer(
          ignoring: !widget.open,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            offset: widget.open ? Offset.zero : const Offset(-1, 0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: widget.open ? 1 : 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: MouseRegion(
                  onEnter: (_) => _setPointerOnPanel(true),
                  onExit: (_) => _setPointerOnPanel(false),
                  child: Focus(
                    focusNode: _panelFocusNode,
                    canRequestFocus: false,
                    descendantsAreFocusable: true,
                    child: ZephyrFloatingOverlayScope(
                      latch: _latch,
                      child: DesktopFloatingSidebarScope(
                        latch: _latch,
                        syncMenuController: _syncMenuController,
                        child: SizedBox(
                      width: panelWidth,
                      child: ZephyrFloatingChrome(
                        borderRadius: BorderRadius.only(
                          topRight: radius.topRight,
                          bottomRight: radius.bottomRight,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topRight: radius.topRight,
                            bottomRight: radius.bottomRight,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: width,
                                child: WorkspaceSidebar(
                                  model: widget.model,
                                  mode: SidebarMode.floating,
                                  openLibrary: widget.openLibrary,
                                  openSettings: widget.openSettings,
                                  onCollapse: _collapse,
                                  aiContextEnabled: widget.aiContextEnabled,
                                  aiContext: widget.aiContext,
                                ),
                              ),
                              SidebarResizeHandle(
                                model: widget.model,
                                maxWidth: widget.maxSidebarWidth,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
