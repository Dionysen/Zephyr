import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../view_models/quick_toolbar_view_model.dart';
import 'quick_toolbar_bar.dart';
import 'quick_toolbar_drawer.dart';
import 'quick_toolbar_edit_sheet.dart';
import 'workspace_editor_bridge.dart';

/// Bottom overlay: toolbar above IME / tools drawer.
class QuickToolbarHost extends StatelessWidget {
  const QuickToolbarHost({
    super.key,
    required this.toolbar,
    required this.bridge,
    required this.foreground,
    required this.child,
  });

  final QuickToolbarViewModel toolbar;
  final WorkspaceEditorBridge bridge;
  final Color foreground;
  final Widget child;

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
  Widget build(BuildContext context) {
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
        final visible =
            bodyFocused && (fixedPanel || keyboard > 0.5);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          toolbar.reportKeyboardInset(keyboard);
          if (!bodyFocused &&
              (toolbar.toolsDrawerOpen || toolbar.holdingPanelForIme)) {
            toolbar.closeToolsDrawer();
          }
        });

        final obstruction = bottomObstruction(
          visible: visible,
          drawerOpen: fixedPanel,
          keyboardInset: keyboard,
          panelHeight: fixedPanel ? panelHeight : 0,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: _BottomObstructionScope(
                obstruction: obstruction,
                child: child,
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
                          foreground: foreground,
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
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: panelHeight,
                      child: QuickToolbarBar(
                        config: toolbar.config,
                        foreground: foreground,
                        toolsDrawerOpen: drawerOpen,
                        canUndo: bridge.canUndo,
                        onToolPressed: (tool) => _onTool(context, tool),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _onTool(BuildContext context, QuickTool tool) {
    switch (tool.kind) {
      case QuickToolKind.tools:
        if (toolbar.toolsDrawerOpen) {
          // Show IME first while the panel slot is still held, then drop the
          // drawer chrome — avoids a blank frame at bottom:0.
          toolbar.restoreImeFromTools();
          bridge.focusBodyAndShowIme();
        } else {
          final keyboard = MediaQuery.viewInsetsOf(context).bottom;
          toolbar.openToolsDrawer(keyboardHeight: keyboard);
          bridge.hideIme();
        }
      case QuickToolKind.undo:
        bridge.undo();
      case QuickToolKind.paste:
        bridge.paste();
      case QuickToolKind.indent:
        bridge.insertIndent();
      case QuickToolKind.format:
        bridge.applyFormat();
      case QuickToolKind.phrase:
        bridge.insertPhrase(tool.payload ?? '');
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
