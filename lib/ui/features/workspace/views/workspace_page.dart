import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/android_storage_access.dart';
import '../../../../data/services/folder_bookmark.dart';
import '../../../../domain/models/library_backup.dart';

import '../../../core/breakpoints.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/quick_toolbar/quick_toolbar_host.dart';
import '../../editor/quick_toolbar/workspace_editor_bridge.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../settings/views/settings_page.dart';
import 'workspace_editor.dart';
import 'workspace_settings_panel.dart';
import 'workspace_sidebar.dart';

/// Adaptive writing workspace. Compact and expanded layouts share the same
/// sidebar, header, and editor rather than forking platform-specific pages.
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage>
    with WidgetsBindingObserver {
  LibraryViewModel? _library;
  var _started = false;
  var _settingsOpen = false;
  var _offeredDraftRecovery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _library = ZephyrScope.of(context).library;
    if (_started) {
      return;
    }
    _started = true;
    unawaited(_bootstrapLibrary());
  }

  Future<void> _bootstrapLibrary() async {
    final library = _library;
    if (library == null) return;
    await library.load();
    if (!mounted || _offeredDraftRecovery) return;
    _offeredDraftRecovery = true;
    await _offerDraftRecovery(library);
  }

  Future<void> _offerDraftRecovery(LibraryViewModel library) async {
    final drafts = List<ArticleDraft>.from(library.recoverableDrafts);
    for (final draft in drafts) {
      if (!mounted) return;
      final l10n = context.l10n;
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.draftRecoverTitle),
          content: Text(l10n.draftRecoverBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'dismiss'),
              child: Text(l10n.draftDismissAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'restore'),
              child: Text(l10n.draftRecoverAction),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == 'restore') {
        await library.applyRecoverableDraft(draft);
      } else if (action == 'dismiss') {
        await library.dismissRecoverableDraft(draft);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final library = _library;
      if (library != null) {
        unawaited(library.flushPending());
      }
      // Auto-backup only on paused (not inactive) to avoid double work and
      // competing with the system transition animation.
      if (mounted && state == AppLifecycleState.paused) {
        unawaited(ZephyrScope.of(context).backup.maybeAutoBackupOnLeave());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final library = _library;
    if (library != null) {
      unawaited(library.flushPending());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.library, scope.theme]),
      builder: (context, _) {
        final model = scope.library;
        final immersiveStatusBar = scope.theme.ui.immersiveStatusBar;
        final hideStatusBarIcons = scope.theme.ui.hideStatusBarIcons;
        final surface = Theme.of(context).colorScheme.surface;
        if (model.error != null && model.library == null) {
          return ZephyrStatusBar(
            immersive: immersiveStatusBar,
            hideIcons: hideStatusBarIcons,
            statusBarColor: surface,
            child: _LibrarySetupPage(
              error: model.error,
              openLibrary: _openLibrary,
            ),
          );
        }
        if (model.library == null) {
          return ZephyrStatusBar(
            immersive: immersiveStatusBar,
            hideIcons: hideStatusBarIcons,
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
              final immersive = immersiveStatusBar;
              final sidebarColor =
                  Theme.of(context).colorScheme.surfaceContainerLowest;
              // Immersive: full-bleed under a transparent status bar; pad chrome
              // only. Off: keep the same edge-to-edge surface, but pad the shell.
              return Theme(
                data: withMobileRoundControls(Theme.of(context)),
                child: ZephyrStatusBar(
                  immersive: immersive,
                  hideIcons: hideStatusBarIcons,
                  statusBarColor: surface,
                  child: Scaffold(
                    backgroundColor: surface,
                    // Keep the editor viewport stable; the plain-text editor
                    // pads its scroll extent by the IME inset so the last line
                    // can sit above the keyboard without a layout resize jump.
                    resizeToAvoidBottomInset: false,
                    body: ColoredBox(
                      color: surface,
                      child: ZephyrTopSafeArea(
                        top: !immersive,
                        // Content paints under the transparent gesture bar.
                        bottom: false,
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
                                  color: sidebarColor,
                                  child: ZephyrTopSafeArea(
                                    // Always paint sidebar under the status band
                                    // when immersive; reserve space for controls.
                                    top: immersive,
                                    bottom: false,
                                    left: false,
                                    right: false,
                                    child: WorkspaceSidebar(
                                      model: model,
                                      mode: SidebarMode.drawer,
                                      openLibrary: _openLibrary,
                                      openSettings: _openSettings,
                                    ),
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
                ),
              );
            }

            final panelWidth = WorkspaceSettingsPanel.preferredWidth.clamp(
              280.0,
              constraints.maxWidth * 0.4,
            );
            final workspace = Row(
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
            final shell = _settingsOpen
                ? Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      final action =
                          scope.keyboardShortcuts.actionForKeyEvent(event);
                      if (action == ShortcutActionId.closeSettings) {
                        _closeSettings();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        workspace,
                        GestureDetector(
                          onTap: _closeSettings,
                          behavior: HitTestBehavior.opaque,
                          child: const ColoredBox(color: Colors.transparent),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _WorkspaceSettingsSlideIn(
                            child: WorkspaceSettingsPanel(
                              width: panelWidth,
                              onClose: _closeSettings,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : workspace;
            return ZephyrStatusBar(
              immersive: immersiveStatusBar,
              hideIcons: hideStatusBarIcons,
              statusBarColor: surface,
              child: Scaffold(
                backgroundColor: surface,
                body: WindowChrome.isDesktop
                    ? SafeArea(top: false, child: shell)
                    : ColoredBox(
                        color: surface,
                        child: ZephyrTopSafeArea(
                          bottom: false,
                          child: shell,
                        ),
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
    final compact = ZephyrBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    if (compact) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
      return;
    }
    setState(() => _settingsOpen = !_settingsOpen);
    if (_settingsOpen) {
      prefetchWorkspaceSettingsFonts(context);
    }
  }

  void _closeSettings() {
    if (!_settingsOpen) {
      return;
    }
    setState(() => _settingsOpen = false);
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
  final _editorBridge = WorkspaceEditorBridge();

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
    _editorBridge.dispose();
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

  Widget _chromeFade({required Widget child, required double travel}) {
    return AnimatedBuilder(
      animation: _hide,
      builder: (context, child) {
        final t = _hide.value;
        return IgnorePointer(
          ignoring: t > 0.85,
          child: Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -travel * t),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Word count: same show/hide gate as the bar, but opacity only (no slide).
  Widget _wordCountFade({required Widget child}) {
    return AnimatedBuilder(
      animation: _hide,
      builder: (context, child) {
        final t = _hide.value;
        return IgnorePointer(
          ignoring: true,
          child: Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
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
    final barBottom = statusTop + _barInset + WorkspaceMobileBookBar.height;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final foreground = theme.colorScheme.onSurface;
    final wordCount = widget.model.article?.wordCount;
    final scope = ZephyrScope.of(context);
    final quickToolbar = scope.quickToolbar;
    final themeVm = scope.theme;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(
            child: ListenableBuilder(
              listenable: Listenable.merge([widget.preferences, themeVm]),
              builder: (context, _) => QuickToolbarHost(
                toolbar: quickToolbar,
                bridge: _editorBridge,
                foreground: foreground,
                bodyFontFamily: widget.preferences.preferences.fontFamily,
                hidden: themeVm.ui.hideQuickToolbar,
                child: WorkspaceEditor(
                  model: widget.model,
                  preferences: widget.preferences,
                  contentTopInset: contentTop,
                  showWordCount: false,
                  bridge: _editorBridge,
                ),
              ),
            ),
          ),
          // Opaque band above the bar's bottom edge — no text, only surface.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: barBottom,
            child: _chromeFade(
              travel: contentTop,
              child: ColoredBox(color: surface),
            ),
          ),
          Positioned(
            top: statusTop + _barInset,
            left: _barSideInset,
            right: _barSideInset,
            child: _chromeFade(
              travel: contentTop,
              child: WorkspaceMobileBookBar(
                model: widget.model,
                onOpenMenu: () => ZephyrSwipeDrawer.of(context).open(),
              ),
            ),
          ),
          if (wordCount != null)
            Positioned(
              // Below the book bar, top-right of the reading area.
              top: statusTop + _barTravel,
              right: 8,
              child: _wordCountFade(
                child: EditorOverlayCapsule(
                  compact: true,
                  child: Text(
                    '$wordCount',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      color: EditorOverlayCapsule.foregroundOf(context),
                    ),
                  ),
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
    final l10n = context.l10n;
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
                    l10n.tempLibraryBannerTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    l10n.tempLibraryBannerSubtitle,
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
              child: Text(l10n.chooseLibraryButton),
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
    final l10n = context.l10n;
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
                    l10n.librarySetupTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.librarySetupBody,
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
                    label: Text(l10n.chooseLibraryDirectoryButton),
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

/// Slides [child] in from the right once when mounted.
class _WorkspaceSettingsSlideIn extends StatefulWidget {
  const _WorkspaceSettingsSlideIn({required this.child});

  final Widget child;

  @override
  State<_WorkspaceSettingsSlideIn> createState() =>
      _WorkspaceSettingsSlideInState();
}

class _WorkspaceSettingsSlideInState extends State<_WorkspaceSettingsSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WorkspaceSettingsPanel.animationDuration,
  )..forward();

  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: _offset,
    child: widget.child,
  );
}
