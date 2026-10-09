import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/android_storage_access.dart';
import '../../../../data/services/folder_bookmark.dart';

import '../../../../domain/models/status_bar_mode.dart';
import '../../../core/breakpoints.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../settings/views/settings_page.dart';
import 'workspace_editor.dart';
import 'workspace_sidebar.dart';

/// Adaptive writing workspace. Compact and expanded layouts share the same
/// sidebar, header, and editor rather than forking platform-specific pages.
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  LibraryViewModel? _library;
  var _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _library = ZephyrScope.of(context).library;
    if (_started) {
      return;
    }
    _started = true;
    _library!.load();
  }

  @override
  void dispose() {
    _library?.save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.library, scope.theme]),
      builder: (context, _) {
        final model = scope.library;
        final statusBarMode = scope.theme.ui.statusBarMode;
        final surface = Theme.of(context).colorScheme.surface;
        if (model.error != null && model.library == null) {
          return ZephyrStatusBar(
            mode: statusBarMode,
            statusBarColor: surface,
            child: _LibrarySetupPage(
              error: model.error,
              openLibrary: _openLibrary,
            ),
          );
        }
        if (model.library == null) {
          return ZephyrStatusBar(
            mode: statusBarMode,
            statusBarColor: surface,
            child: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = ZephyrBreakpoints.isCompact(constraints.maxWidth);
            if (compact) {
              final drawerWidth = model.sidebarWidth.clamp(
                260.0,
                constraints.maxWidth * 0.88,
              );
              final immersive =
                  statusBarMode == StatusBarMode.immersive;
              return ZephyrStatusBar(
                mode: statusBarMode,
                statusBarColor: surface,
                child: Scaffold(
                  backgroundColor: surface,
                  body: ColoredBox(
                    color: surface,
                    child: ZephyrTopSafeArea(
                      // Immersive: editor may draw under the status band;
                      // chrome (banner / drawer / initial top bar) still pads.
                      top: !immersive,
                      child: Column(
                        children: [
                          if (model.needsLibrarySetup)
                            Padding(
                              padding: EdgeInsets.only(
                                top: immersive ? zephyrTopInset(context) : 0,
                              ),
                              child: _LibrarySetupBanner(
                                openLibrary: _openLibrary,
                              ),
                            ),
                          Expanded(
                            child: ZephyrSwipeDrawer(
                              drawerWidth: drawerWidth,
                              drawer: Material(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLowest,
                                child: immersive
                                    ? ZephyrTopSafeArea(
                                        bottom: false,
                                        left: false,
                                        right: false,
                                        child: WorkspaceSidebar(
                                          model: model,
                                          mode: SidebarMode.drawer,
                                          openLibrary: _openLibrary,
                                          openSettings: _openSettings,
                                        ),
                                      )
                                    : WorkspaceSidebar(
                                        model: model,
                                        mode: SidebarMode.drawer,
                                        openLibrary: _openLibrary,
                                        openSettings: _openSettings,
                                      ),
                              ),
                              body: _MobileEditorChrome(
                                model: model,
                                preferences: scope.editorPreferences,
                                invadeStatusBar: immersive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final shell = Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: model.isResizingSidebar
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: model.isSidebarExpanded ? model.sidebarWidth : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: model.sidebarWidth,
                      maxWidth: model.sidebarWidth,
                      child: WorkspaceSidebar(
                        model: model,
                        mode: SidebarMode.docked,
                        openLibrary: _openLibrary,
                        openSettings: _openSettings,
                      ),
                    ),
                  ),
                ),
                if (model.isSidebarExpanded)
                  SidebarResizeHandle(
                    model: model,
                    maxWidth: _maxSidebarWidth(constraints.maxWidth),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (model.needsLibrarySetup)
                        _LibrarySetupBanner(openLibrary: _openLibrary),
                      WorkspaceHeader(
                        model: model,
                        showSidebarToggle: !model.isSidebarExpanded,
                      ),
                      Expanded(
                        child: WorkspaceEditor(
                          model: model,
                          preferences: scope.editorPreferences,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            return ZephyrStatusBar(
              mode: statusBarMode,
              statusBarColor: surface,
              child: Scaffold(
                backgroundColor: surface,
                body: WindowChrome.isDesktop
                    ? SafeArea(top: false, child: shell)
                    : ColoredBox(
                        color: surface,
                        child: ZephyrTopSafeArea(child: shell),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLibrary() async {
    final picked = await _pickLibraryFolder();
    if (picked != null && mounted) {
      await ZephyrScope.of(context).library
          .openLibrary(picked.path, bookmark: picked.bookmark);
    }
  }

  Future<PickedLibraryFolder?> _pickLibraryFolder() async {
    if (Platform.isAndroid) {
      // PureWriter libraries under Documents need all-files access to open
      // App/Room.db with dart:io / sqflite.
      try {
        await AndroidStorageAccess().ensureFullAccess();
      } on Object {
        // Settings intent is best-effort; picker may still succeed.
      }
    }
    if (Platform.isMacOS) {
      try {
        return await FolderBookmarkAccess().pickDirectory();
      } on Object {
        // Native folder chrome is optional in tests and unsupported embeds.
      }
    }
    final root = await FilePicker.getDirectoryPath();
    if (root == null) {
      return null;
    }
    return PickedLibraryFolder(path: root);
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  double _maxSidebarWidth(double workspaceWidth) {
    final available = workspaceWidth - 360 - SidebarResizeHandle.width;
    return available.clamp(
      LibraryViewModel.minSidebarWidth,
      LibraryViewModel.maxSidebarWidth,
    );
  }
}

/// Compact editor + floating book bar that slides away while reading down
/// and returns when scrolling back up.
class _MobileEditorChrome extends StatefulWidget {
  const _MobileEditorChrome({
    required this.model,
    required this.preferences,
    this.invadeStatusBar = false,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;

  /// When true, the editor extends under the status band so scrolled text can
  /// enter it naturally. Top-bar show/hide never changes scroll padding.
  final bool invadeStatusBar;

  @override
  State<_MobileEditorChrome> createState() => _MobileEditorChromeState();
}

class _MobileEditorChromeState extends State<_MobileEditorChrome>
    with SingleTickerProviderStateMixin {
  static const _barInset = 8.0;
  static const _barSideInset = 12.0;
  static const _barGapBelow = 6.0;

  /// Ignore small scrolls until this much movement accumulates in one direction.
  static const _engageSlop = 36.0;

  /// Snappy ease that settles on the target without overshoot.
  static const _motion = Cubic(0.2, 0.0, 0.0, 1.0);

  late final AnimationController _hide;

  /// Accumulated delta before triggering a show/hide jump.
  var _slop = 0.0;
  String? _articleId;

  double get _barTravel =>
      _barInset + WorkspaceMobileBookBar.height + _barGapBelow;

  bool get _isHidden => _hide.value >= 0.999;
  bool get _isVisible => _hide.value <= 0.001;

  @override
  void initState() {
    super.initState();
    _hide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 0,
    );
  }

  @override
  void dispose() {
    _hide.dispose();
    super.dispose();
  }

  void _resetGate() {
    _slop = 0;
  }

  void _showBar({bool immediate = false}) {
    _resetGate();
    if (immediate) {
      _hide.value = 0;
      return;
    }
    if (_isVisible && !_hide.isAnimating) {
      return;
    }
    _hide.animateTo(0, curve: _motion);
  }

  void _hideBar() {
    _resetGate();
    if (_isHidden && !_hide.isAnimating) {
      return;
    }
    _hide.animateTo(1, curve: _motion);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta == null || delta == 0) {
        return false;
      }
      // At the top of the document, always pin the bar visible.
      if (notification.metrics.pixels <= 0) {
        if (!_isVisible || _slop != 0) {
          _showBar();
        }
        return false;
      }

      final dir = delta > 0 ? 1 : -1;
      // Restart slop when the finger reverses before the threshold.
      if (_slop != 0 && _slop.sign != dir) {
        _slop = 0;
      }
      _slop += delta;
      if (_slop.abs() < _engageSlop) {
        return false;
      }

      if (dir > 0) {
        _hideBar();
      } else {
        _showBar();
      }
    } else if (notification is ScrollEndNotification) {
      _resetGate();
      if (notification.metrics.pixels <= 0) {
        _showBar();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final articleId = widget.model.article?.id;
    if (articleId != _articleId) {
      _articleId = articleId;
      _showBar(immediate: true);
    }
    final statusTop =
        widget.invadeStatusBar ? zephyrTopInset(context) : 0.0;
    // Keep scroll padding stable — bar show/hide must not reflow the editor.
    final contentTop = statusTop + _barTravel;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(
            child: WorkspaceEditor(
              model: widget.model,
              preferences: widget.preferences,
              contentTopInset: contentTop,
            ),
          ),
          Positioned(
            top: statusTop + _barInset,
            left: _barSideInset,
            right: _barSideInset,
            child: AnimatedBuilder(
              animation: _hide,
              builder: (context, child) {
                final t = _hide.value;
                return IgnorePointer(
                  ignoring: t > 0.85,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -contentTop * t),
                      child: child,
                    ),
                  ),
                );
              },
              child: WorkspaceMobileBookBar(
                model: widget.model,
                onOpenMenu: () => ZephyrSwipeDrawer.of(context).open(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibrarySetupBanner extends StatelessWidget {
  const _LibrarySetupBanner({required this.openLibrary});

  final Future<void> Function() openLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              Icons.folder_open_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前使用临时书库',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    '选择 PureWriter 书库目录以打开你的作品',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: openLibrary,
              child: const Text('选择书库'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySetupPage extends StatelessWidget {
  const _LibrarySetupPage({
    required this.openLibrary,
    this.error,
  });

  final Object? error;
  final Future<void> Function() openLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ZephyrTopSafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '选择 PureWriter 书库',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zephyr 需要打开包含 App/Room.db 的书库目录。'
                    '也可以先使用临时书库开始写作，稍后再切换。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '$error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: openLibrary,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('选择书库目录'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
