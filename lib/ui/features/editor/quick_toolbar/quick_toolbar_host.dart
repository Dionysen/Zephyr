import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
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
    required this.child,
    this.bodyFontFamily,
    this.hidden = false,
  });

  final QuickToolbarViewModel toolbar;
  final WorkspaceEditorBridge bridge;
  final Color foreground;
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
      return (quickToolbarHeight + panelHeight - keyboardInset)
          .clamp(quickToolbarHeight, double.infinity);
    }
    if (keyboardInset > 0.5) return quickToolbarHeight;
    return 0;
  }

  @override
  State<QuickToolbarHost> createState() => _QuickToolbarHostState();
}

class _QuickToolbarHostState extends State<QuickToolbarHost> {
  late final ToolsPanelToggleGate _toolsGate;

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
    _toolsGate.dispose();
    super.dispose();
  }

  void _commitToolsDrawer(bool open) {
    final toolbar = widget.toolbar;
    final bridge = widget.bridge;
    if (open) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      toolbar.openToolsDrawer(keyboardHeight: keyboard);
      bridge.hideIme();
    } else {
      // Show IME first while the panel slot is still held, then drop
      // the drawer chrome — avoids a blank frame at bottom:0.
      toolbar.restoreImeFromTools();
      bridge.focusBodyAndShowIme();
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
        final panelHeight =
            fixedPanel ? math.max(latched, keyboard) : keyboard;
        final visible = !widget.hidden &&
            bodyFocused &&
            (fixedPanel || keyboard > 0.5);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.hidden &&
              (toolbar.toolsDrawerOpen || toolbar.holdingPanelForIme)) {
            final wasDrawer = toolbar.toolsDrawerOpen;
            toolbar.closeToolsDrawer();
            _toolsGate.markSettled();
            if (wasDrawer) bridge.focusBodyAndShowIme();
            return;
          }
          toolbar.reportKeyboardInset(keyboard);
          _syncToolsGateSettle(keyboard);
          if (!bodyFocused &&
              (toolbar.toolsDrawerOpen || toolbar.holdingPanelForIme)) {
            toolbar.closeToolsDrawer();
            _toolsGate.markSettled();
          }
        });

        final obstruction = QuickToolbarHost.bottomObstruction(
          visible: visible,
          drawerOpen: fixedPanel,
          keyboardInset: keyboard,
          panelHeight: fixedPanel ? panelHeight : 0,
        );

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
                // Toolbar / drawer must never steal focus from the body caret.
                ExcludeFocus(
                  child: Stack(
                    children: [
                      if (drawerOpen)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: QuickToolbarDrawer(
                            height: panelHeight,
                            foreground: widget.foreground,
                            onEditToolbar: () {
                              showQuickToolbarEditSheet(
                                context,
                                toolbar: toolbar,
                              );
                            },
                          ),
                        ),
                      // While holding for IME: leave the slot empty so the system
                      // keyboard paints in without a Flutter flash frame.
                      // Stable key: when the drawer Positioned is inserted/removed
                      // above this slot, Flutter must not recreate the bar (that
                      // was snapping the tools-icon spin on close).
                      Positioned(
                        key: const ValueKey<String>('ime_quick_toolbar_bar'),
                        left: 0,
                        right: 0,
                        bottom: panelHeight,
                        child: QuickToolbarBar(
                          config: toolbar.config,
                          foreground: widget.foreground,
                          toolsDrawerOpen: drawerOpen,
                          canUndo: bridge.canUndo,
                          bodyFontFamily: widget.bodyFontFamily,
                          onToolPressed: (tool) => _onTool(context, tool),
                        ),
                      ),
                    ],
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
    final scope =
        context.dependOnInheritedWidgetOfExactType<_BottomObstructionScope>();
    return scope?.obstruction ?? 0;
  }

  @override
  bool updateShouldNotify(_BottomObstructionScope oldWidget) =>
      obstruction != oldWidget.obstruction;
}

double quickToolbarBottomObstructionOf(BuildContext context) =>
    _BottomObstructionScope.of(context);
