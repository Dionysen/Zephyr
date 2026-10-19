import 'dart:async';

import 'package:flutter/material.dart';

import '../../editor/view_models/library_view_model.dart';
import '../models/workspace_ai_context_selection.dart';
import '../../../core/zephyr_floating_chrome.dart';
import '../../../core/zephyr_floating_overlay_latch.dart';
import '../../../core/zephyr_theme.dart';
import 'workspace_ai_chat_view.dart';
import 'workspace_sidebar.dart';

/// Right-edge hover zone that reveals the floating AI panel.
const double kDesktopFloatingAiPanelEdgeWidth = 20;

/// Desktop overlay AI chat: does not consume horizontal layout space.
class DesktopFloatingAiPanel extends StatefulWidget {
  const DesktopFloatingAiPanel({
    super.key,
    required this.model,
    required this.open,
    required this.onOpenChanged,
    required this.maxAiPanelWidth,
    required this.contextSelection,
    required this.onOpenDesktopAiSettings,
  });

  final LibraryViewModel model;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final double maxAiPanelWidth;
  final WorkspaceAiContextSelection contextSelection;
  final VoidCallback onOpenDesktopAiSettings;

  @override
  State<DesktopFloatingAiPanel> createState() => _DesktopFloatingAiPanelState();
}

class _DesktopFloatingAiPanelState extends State<DesktopFloatingAiPanel> {
  var _pointerOnEdge = false;
  var _pointerOnPanel = false;
  Timer? _closeTimer;
  final _panelFocusNode = FocusNode(skipTraversal: true);
  final _latch = ZephyrFloatingOverlayLatch();

  @override
  void dispose() {
    _closeTimer?.cancel();
    _panelFocusNode.dispose();
    super.dispose();
  }

  bool _focusInPanel() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context == null) return false;
    return focus!.context!
            .findAncestorStateOfType<_DesktopFloatingAiPanelState>() !=
        null;
  }

  bool _shouldKeepOpen() {
    if (_pointerOnEdge || _pointerOnPanel) return true;
    if (_latch.isHeld) return true;
    if (_panelFocusNode.hasFocus) return true;
    if (_focusInPanel()) return true;
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

  @override
  Widget build(BuildContext context) {
    final width = widget.model.aiPanelWidth;
    final panelWidth = width + AiPanelResizeHandle.width;
    final radius = context.zephyrBarBorderRadius;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: kDesktopFloatingAiPanelEdgeWidth,
          child: MouseRegion(
            onEnter: (_) => _setPointerOnEdge(true),
            onExit: (_) => _setPointerOnEdge(false),
            child: const SizedBox.expand(),
          ),
        ),
        IgnorePointer(
          ignoring: !widget.open,
          child: AnimatedSlide(
            duration: widget.model.isResizingAiPanel
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            offset: widget.open ? Offset.zero : const Offset(1, 0),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: widget.open ? 1 : 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: MouseRegion(
                  onEnter: (_) => _setPointerOnPanel(true),
                  onExit: (_) => _setPointerOnPanel(false),
                  child: Focus(
                    focusNode: _panelFocusNode,
                    canRequestFocus: false,
                    descendantsAreFocusable: true,
                    onFocusChange: (_) => _syncOpen(),
                    child: ZephyrFloatingOverlayScope(
                      latch: _latch,
                      child: SizedBox(
                        width: panelWidth,
                        child: ZephyrFloatingChrome(
                          borderRadius: BorderRadius.only(
                            topLeft: radius.topLeft,
                            bottomLeft: radius.bottomLeft,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: radius.topLeft,
                              bottomLeft: radius.bottomLeft,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AiPanelResizeHandle(
                                  model: widget.model,
                                  maxWidth: widget.maxAiPanelWidth,
                                ),
                                SizedBox(
                                  width: width,
                                  child: ColoredBox(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLowest,
                                    child: WorkspaceAiChatView(
                                      contextSelection:
                                          widget.contextSelection,
                                      libraryModel: widget.model,
                                      onOpenDesktopAiSettings:
                                          widget.onOpenDesktopAiSettings,
                                    ),
                                  ),
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
      ],
    );
  }
}
