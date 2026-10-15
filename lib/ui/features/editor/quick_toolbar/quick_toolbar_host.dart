import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../view_models/editor_preferences_view_model.dart';
import '../view_models/quick_toolbar_view_model.dart';
import 'quick_toolbar_bar.dart';
import 'quick_toolbar_drawer.dart';
import 'quick_toolbar_edit_sheet.dart';
import 'tools_panel_toggle_gate.dart';
import 'workspace_editor_bridge.dart';

/// Bottom overlay: toolbar above IME / tools drawer.
class QuickToolbarHost extends StatefulWidget {
  const QuickToolbarHost({
    super.key,
    required this.toolbar,
    required this.bridge,
    required this.foreground,
    required this.editorPreferences,
    required this.child,
    this.bodyFontFamily,
    this.hidden = false,
  });

  final QuickToolbarViewModel toolbar;
  final WorkspaceEditorBridge bridge;
  final Color foreground;
  final EditorPreferencesViewModel editorPreferences;
  final Widget child;

  /// Article body font for phrase chips on the bar.
  final String? bodyFontFamily;

  /// When true, the bar and tools panel are not shown (IME inset unchanged).
  final bool hidden;

  /// Extra inset layered on top of [MediaQuery.viewInsets].
  ///
  /// While the tools panel is open the soft keyboard animates to zero; this
  /// value shrinks by the same amount so
  /// `viewInsets + obstruction == toolbar + panel` stays constant — toolbar
  /// Y and document scroll do not jump.
  static double bottomObstruction({
    required bool visible,
    required bool drawerOpen,
    required double keyboardInset,
    required double panelHeight,
  }) {
    if (!visible) return 0;
    if (drawerOpen) {
      return (quickToolbarHeight + panelHeight - keyboardInset).clamp(
        quickToolbarHeight,
        double.infinity,
      );
    }
    if (keyboardInset > 0.5) return quickToolbarHeight;
    return 0;
  }

  @override
  State<QuickToolbarHost> createState() => _QuickToolbarHostState();
}

class _QuickToolbarHostState extends State<QuickToolbarHost> {
  late final ToolsPanelToggleGate _toolsGate;
  bool? _librarySidebarSwipeBlocked;

  @override
  void initState() {
    super.initState();
    _toolsGate = ToolsPanelToggleGate(
      isDrawerOpen: () => widget.toolbar.toolsDrawerOpen,
      onCommit: _commitToolsDrawer,
    );
  }

  @override
  void dispose() {
    if (_librarySidebarSwipeBlocked == true) {
      ZephyrLibrarySidebarSwipeBlockNotification(blocked: false)
          .dispatch(context);
    }
    _toolsGate.dispose();
    super.dispose();
  }

  void _syncLibrarySidebarSwipeBlock(bool blocked) {
    if (_librarySidebarSwipeBlocked == blocked) return;
    _librarySidebarSwipeBlocked = blocked;
    ZephyrLibrarySidebarSwipeBlockNotification(blocked: blocked)
        .dispatch(context);
  }

  void _commitToolsDrawer(bool open) {
    final toolbar = widget.toolbar;
    final bridge = widget.bridge;
    if (open) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      toolbar.openToolsDrawer(keyboardHeight: keyboard);
      // Keep body focus; hide keyboard and block re-show until tools close
      // or the body actually loses focus.
      bridge.setSuppressBodyIme(true);
      bridge.hideIme();
      _syncLibrarySidebarSwipeBlock(true);
    } else {
      // Show IME first while the panel slot is still held, then drop
      // the drawer chrome — avoids a blank frame at bottom:0.
      toolbar.restoreImeFromTools();
      bridge.focusBodyAndShowIme();
      _syncLibrarySidebarSwipeBlock(false);
    }
  }

  void _syncToolsGateSettle(double keyboard) {
    final toolbar = widget.toolbar;
    if (!_toolsGate.isBusy) return;
    if (toolbar.toolsDrawerOpen) {
      // Open commit: wait until the soft keyboard is essentially gone.
      if (keyboard < 8) _toolsGate.markSettled();
      return;
    }
    // Close commit: wait until the IME has filled the latched slot.
    if (!toolbar.holdingPanelForIme && keyboard > 40) {
      _toolsGate.markSettled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = widget.toolbar;
    final bridge = widget.bridge;
    return ListenableBuilder(
      listenable: Listenable.merge([toolbar, bridge]),
      builder: (context, _) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final bodyFocused = bridge.bodyFocused;
        final drawerOpen = toolbar.toolsDrawerOpen;
        final fixedPanel = toolbar.usesFixedPanel;
        final latched = toolbar.toolsPanelHeight;
        // While the panel slot is owned (drawer or IME restore), pin the bar to
        // the latched height — but never below the live keyboard (overshoot).
        final panelHeight = fixedPanel ? math.max(latched, keyboard) : keyboard;
        // While the tools panel is latched, stay visible even if a blank panel
        // tap briefly drops primary focus before we restore it.
        final visible =
            !widget.hidden && (fixedPanel || (bodyFocused && keyboard > 0.5));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (widget.hidden &&
              (toolbar.toolsDrawerOpen || toolbar.holdingPanelForIme)) {
            final wasDrawer = toolbar.toolsDrawerOpen;
            toolbar.closeToolsDrawer();
            bridge.setSuppressBodyIme(false);
            _toolsGate.markSettled();
            if (wasDrawer) bridge.focusBodyAndShowIme();
            return;
          }
          // Keep suppress in sync if the drawer was closed via focus loss.
          if (!drawerOpen && bridge.suppressBodyIme) {
            bridge.setSuppressBodyIme(false);
          } else if (drawerOpen && !bridge.suppressBodyIme) {
            bridge.setSuppressBodyIme(true);
          }
          toolbar.reportKeyboardInset(keyboard);
          _syncToolsGateSettle(keyboard);
          // Do not close an open tools drawer here — panel taps briefly drop
          // primary focus and [bodyFocused] in this closure can be stale.
          // Dismiss via tools toggle, system back, or chrome focus (title).
          if (!bridge.bodyFocused &&
              !toolbar.toolsDrawerOpen &&
              toolbar.holdingPanelForIme) {
            toolbar.closeToolsDrawer();
            bridge.setSuppressBodyIme(false);
            _toolsGate.markSettled();
          }
        });

        final obstruction = QuickToolbarHost.bottomObstruction(
          visible: visible,
          drawerOpen: fixedPanel,
          keyboardInset: keyboard,
          panelHeight: fixedPanel ? panelHeight : 0,
        );
        final chromeHeight =
            quickToolbarHeight + (drawerOpen ? panelHeight : 0);
        final chromeBottom = drawerOpen ? 0.0 : panelHeight;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _syncLibrarySidebarSwipeBlock(drawerOpen);
        });

        return PopScope(
          canPop: !drawerOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && drawerOpen) {
              _toolsGate.close();
            }
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: _BottomObstructionScope(
                  obstruction: obstruction,
                  child: widget.child,
                ),
              ),
              if (visible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: chromeBottom,
                  height: chromeHeight,
                  child: ZephyrSwipeDrawerDragShield(
                    child: ExcludeFocus(
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) =>
                            bridge.retainBodyFocusForToolsOverlay(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            QuickToolbarBar(
                              key: const ValueKey<String>(
                                'ime_quick_toolbar_bar',
                              ),
                              config: toolbar.config,
                              foreground: widget.foreground,
                              toolsDrawerOpen: drawerOpen,
                              canUndo: bridge.canUndo,
                              bodyFontFamily: widget.bodyFontFamily,
                              onToolPressed: (tool) => _onTool(context, tool),
                              onReorderPinned: toolbar.reorderPinned,
                              onReorderCustom: toolbar.reorderCustom,
                            ),
                            if (drawerOpen)
                              QuickToolbarDrawer(
                                height: panelHeight,
                                foreground: widget.foreground,
                                editorPreferences: widget.editorPreferences,
                                onEditToolbar: () {
                                  showQuickToolbarEditSheet(
                                    context,
                                    toolbar: toolbar,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onTool(BuildContext context, QuickTool tool) {
    switch (tool.kind) {
      case QuickToolKind.tools:
        // Defer + coalesce via [_toolsGate] so splash can play and rapid taps
        // cannot stack hide/show IME races.
        _toolsGate.toggle();
      case QuickToolKind.undo:
        widget.bridge.undo();
      case QuickToolKind.paste:
        widget.bridge.paste();
      case QuickToolKind.indent:
        widget.bridge.insertIndent();
      case QuickToolKind.format:
        widget.bridge.applyFormat();
      case QuickToolKind.phrase:
        widget.bridge.insertPhrase(tool.payload ?? '');
    }
  }
}

/// Propagates overlay height to [WorkspaceEditor] / plain-text editor.
class _BottomObstructionScope extends InheritedWidget {
  const _BottomObstructionScope({
    required this.obstruction,
    required super.child,
  });

  final double obstruction;

  static double of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_BottomObstructionScope>();
    return scope?.obstruction ?? 0;
  }

  @override
  bool updateShouldNotify(_BottomObstructionScope oldWidget) =>
      obstruction != oldWidget.obstruction;
}

double quickToolbarBottomObstructionOf(BuildContext context) =>
    _BottomObstructionScope.of(context);
