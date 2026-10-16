import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../workspace/views/library_search_sheet.dart';
import '../view_models/editor_preferences_view_model.dart';
import '../view_models/library_view_model.dart';
import '../view_models/quick_toolbar_view_model.dart';
import 'quick_toolbar_bar.dart';
import 'quick_toolbar_drawer.dart';
import 'quick_toolbar_edit_sheet.dart';
import 'quick_toolbar_format_drawer.dart';
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
    this.library,
    this.bodyFontFamily,
    this.hidden = false,
  });

  final QuickToolbarViewModel toolbar;
  final WorkspaceEditorBridge bridge;
  final Color foreground;
  final EditorPreferencesViewModel editorPreferences;
  final Widget child;

  /// Editor session used by contextual actions such as library search.
  /// Defaults to the application-primary session for existing single-editor
  /// hosts; the compact two-page workspace supplies its active session.
  final LibraryViewModel? library;

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
  late final ToolsPanelToggleGate _formatGate;
  bool? _librarySidebarSwipeBlocked;

  @override
  void initState() {
    super.initState();
    _toolsGate = ToolsPanelToggleGate(
      isDrawerOpen: () => widget.toolbar.toolsDrawerOpen,
      onCommit: _commitToolsDrawer,
    );
    _formatGate = ToolsPanelToggleGate(
      isDrawerOpen: () => widget.toolbar.formatDrawerOpen,
      onCommit: _commitFormatDrawer,
    );
    widget.toolbar.handleAuxiliaryPanelBack = _handleAuxiliaryPanelBack;
  }

  @override
  void dispose() {
    widget.toolbar.handleAuxiliaryPanelBack = null;
    if (_librarySidebarSwipeBlocked == true) {
      ZephyrLibrarySidebarSwipeBlockNotification(blocked: false)
          .dispatch(context);
    }
    _toolsGate.dispose();
    _formatGate.dispose();
    super.dispose();
  }

  bool _handleAuxiliaryPanelBack() {
    if (widget.toolbar.toolsDrawerOpen) {
      _toolsGate.close();
      return true;
    }
    if (widget.toolbar.formatDrawerOpen) {
      _formatGate.close();
      return true;
    }
    return false;
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
      bridge.setSuppressBodyIme(true);
      bridge.hideIme();
      _syncLibrarySidebarSwipeBlock(true);
    } else {
      toolbar.restoreImeFromAuxiliaryPanel();
      bridge.focusBodyAndShowIme();
      if (!toolbar.formatDrawerOpen) {
        _syncLibrarySidebarSwipeBlock(false);
      }
    }
  }

  void _commitFormatDrawer(bool open) {
    final toolbar = widget.toolbar;
    final bridge = widget.bridge;
    if (open) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      toolbar.openFormatDrawer(keyboardHeight: keyboard);
      bridge.setSuppressBodyIme(true);
      bridge.hideIme();
      _syncLibrarySidebarSwipeBlock(true);
    } else {
      toolbar.restoreImeFromAuxiliaryPanel();
      bridge.focusBodyAndShowIme();
      if (!toolbar.toolsDrawerOpen) {
        _syncLibrarySidebarSwipeBlock(false);
      }
    }
  }

  void _syncAuxiliaryGateSettle(
    double keyboard,
    QuickToolbarViewModel toolbar,
  ) {
    if (_toolsGate.isBusy) {
      if (toolbar.toolsDrawerOpen) {
        if (keyboard < 8) _toolsGate.markSettled();
      } else if (!toolbar.holdingPanelForIme && keyboard > 40) {
        _toolsGate.markSettled();
      }
    }
    if (_formatGate.isBusy) {
      if (toolbar.formatDrawerOpen) {
        if (keyboard < 8) _formatGate.markSettled();
      } else if (!toolbar.holdingPanelForIme && keyboard > 40) {
        _formatGate.markSettled();
      }
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
        final toolsOpen = toolbar.toolsDrawerOpen;
        final formatOpen = toolbar.formatDrawerOpen;
        final auxiliaryOpen = toolsOpen || formatOpen;
        final fixedPanel = toolbar.usesFixedPanel;
        final latched = toolbar.toolsPanelHeight;
        final panelHeight = fixedPanel ? math.max(latched, keyboard) : keyboard;
        final visible =
            !widget.hidden && (fixedPanel || (bodyFocused && keyboard > 0.5));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (widget.hidden && (auxiliaryOpen || toolbar.holdingPanelForIme)) {
            final wasTools = toolbar.toolsDrawerOpen;
            final wasFormat = toolbar.formatDrawerOpen;
            toolbar.closeToolsDrawer();
            toolbar.closeFormatDrawer();
            bridge.setSuppressBodyIme(false);
            _toolsGate.markSettled();
            _formatGate.markSettled();
            if (wasTools || wasFormat) bridge.focusBodyAndShowIme();
            return;
          }
          if (!auxiliaryOpen && bridge.suppressBodyIme) {
            bridge.setSuppressBodyIme(false);
          } else if (auxiliaryOpen && !bridge.suppressBodyIme) {
            bridge.setSuppressBodyIme(true);
          }
          toolbar.reportKeyboardInset(keyboard);
          _syncAuxiliaryGateSettle(keyboard, toolbar);
          if (!bridge.bodyFocused &&
              !toolsOpen &&
              !formatOpen &&
              toolbar.holdingPanelForIme) {
            toolbar.closeToolsDrawer();
            toolbar.closeFormatDrawer();
            bridge.setSuppressBodyIme(false);
            _toolsGate.markSettled();
            _formatGate.markSettled();
          }
        });

        final obstruction = QuickToolbarHost.bottomObstruction(
          visible: visible,
          drawerOpen: fixedPanel,
          keyboardInset: keyboard,
          panelHeight: fixedPanel ? panelHeight : 0,
        );
        final chromeHeight =
            quickToolbarHeight + (auxiliaryOpen ? panelHeight : 0);
        final chromeBottom = auxiliaryOpen ? 0.0 : panelHeight;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _syncLibrarySidebarSwipeBlock(auxiliaryOpen);
        });

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (toolsOpen) {
              _toolsGate.close();
            } else if (formatOpen) {
              _formatGate.close();
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
                              toolsDrawerOpen: toolsOpen,
                              formatDrawerOpen: formatOpen,
                              canUndo: bridge.canUndo,
                              bodyFontFamily: widget.bodyFontFamily,
                              onToolPressed: (tool) => _onTool(context, tool),
                              onReorderPinned: toolbar.reorderPinned,
                              onReorderCustom: toolbar.reorderCustom,
                            ),
                            if (toolsOpen)
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
                            if (formatOpen)
                              QuickToolbarFormatDrawer(
                                height: panelHeight,
                                foreground: widget.foreground,
                                toolbar: toolbar,
                                onApplyAll: () {
                                  bridge.applyFormatOptions(
                                    toolbar.formatSelection.selected,
                                  );
                                },
                                onApplyOption: bridge.applyFormatOption,
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
        _toolsGate.toggle();
      case QuickToolKind.undo:
        widget.bridge.undo();
      case QuickToolKind.paste:
        widget.bridge.paste();
      case QuickToolKind.indent:
        widget.bridge.insertIndent();
      case QuickToolKind.format:
        _formatGate.toggle();
      case QuickToolKind.search:
        unawaited(
          showLibrarySearchSheet(
            context,
            model: widget.library ?? ZephyrScope.of(context).library,
          ),
        );
      case QuickToolKind.timestamp:
        widget.bridge.insertTimestamp(
          localeName: Localizations.localeOf(context).toString(),
        );
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
