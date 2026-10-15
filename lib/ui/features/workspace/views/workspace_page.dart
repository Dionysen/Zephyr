import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/services/android_storage_access.dart';
import '../../../../data/services/folder_bookmark.dart';
import '../../../../data/services/android_leave_backup.dart';
import '../../../../data/services/mobile_background_backup.dart';
import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../../../domain/models/library_backup.dart';
import '../../../../domain/models/theme_color_pack.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/workspace_layout.dart';

import '../../../core/breakpoints.dart';
import '../../../core/editor_background_layer.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_snackbar.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/quick_toolbar/quick_toolbar_host.dart';
import '../../editor/quick_toolbar/workspace_editor_bridge.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../settings/view_models/theme_view_model.dart';
import '../../settings/views/backup_settings_view.dart';
import '../../settings/views/settings_page.dart';
import 'cloud_backup_quick_button.dart';
import 'library_search_sheet.dart';
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

  /// Chrome title when the in-editor chapter title has scrolled away.
  var _showTitleInChrome = false;

  /// Avoid enqueueing leave backup twice across leave-hint → paused → detached.
  var _leaveBackupScheduled = false;

  /// Root back is exiting after scheduling background backup.
  var _handlingExit = false;
  Object? _leaveBackupError;
  Object? _reportedSaveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Home / Recents / kill path: enqueue WorkManager while still allowed.
    AndroidLeaveBackup.listenForUserLeaving(() {
      if (!mounted || WindowChrome.isDesktop || _handlingExit) return;
      _queueLeaveBackup();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _library = ZephyrScope.of(context).library;
    if (_started) {
      return;
    }
    _started = true;
    _library!.addListener(_reportSaveError);
    unawaited(_bootstrapLibrary());
  }

  void _reportSaveError() {
    final error = _library?.saveError;
    if (error == null) {
      _reportedSaveError = null;
      return;
    }
    if (identical(error, _reportedSaveError)) return;
    _reportedSaveError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ZephyrSnackBar.show(context, context.l10n.saveFailed(error.toString()));
      }
    });
  }

  Future<void> _bootstrapLibrary() async {
    final library = _library;
    if (library == null) return;
    await library.load();
    if (!mounted) return;
    if (!_offeredDraftRecovery) {
      _offeredDraftRecovery = true;
      await _offerDraftRecovery(library);
    }
    if (!mounted) return;
    // After draft UI: catch up any cloud upload missed after process death.
    unawaited(ZephyrScope.of(context).cloudSync.catchUpPendingCloudBackup());
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
        unawaited(
          library.flushPending().catchError((Object error) {
            _leaveBackupError = error;
          }),
        );
      }
      // Safety net if [onUserLeaveHint] did not fire (some OEM paths).
      if (mounted &&
          !WindowChrome.isDesktop &&
          !_handlingExit &&
          (state == AppLifecycleState.paused ||
              state == AppLifecycleState.detached)) {
        _queueLeaveBackup();
      }
    } else if (mounted &&
        !WindowChrome.isDesktop &&
        state == AppLifecycleState.resumed) {
      if (!_handlingExit) {
        _leaveBackupScheduled = false;
      }
      final leaveError = _leaveBackupError;
      _leaveBackupError = null;
      if (leaveError != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ZephyrSnackBar.show(
              context,
              context.l10n.backupFailed(leaveError.toString()),
            );
          }
        });
      }
    }
  }

  /// Root back flushes local edits, enqueues background backup, then exits.
  ///
  /// Does not wait for cloud upload — WorkManager (or next launch catch-up)
  /// finishes the `.pwb` when possible.
  Future<void> _onRootBack() async {
    if (_handlingExit) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    if (WindowChrome.isDesktop) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _handlingExit = true;
    try {
      final scope = ZephyrScope.of(context);
      await scope.library.flushPending();
      if (!mounted) return;
      await _scheduleLeaveBackup();
      await SystemNavigator.pop();
      _handlingExit = false;
    } on Object catch (error) {
      if (!mounted) return;
      _handlingExit = false;
      ZephyrSnackBar.show(context, context.l10n.backupFailed(error.toString()));
    }
  }

  void _queueLeaveBackup() {
    unawaited(
      _scheduleLeaveBackup().catchError((Object error) {
        _leaveBackupError = error;
      }),
    );
  }

  /// Flush pending edits and enqueue WorkManager (in-progress notify only).
  Future<void> _scheduleLeaveBackup() async {
    if (_leaveBackupScheduled || !mounted) return;
    final scope = ZephyrScope.of(context);
    await scope.library.flushPending();
    if (!mounted) return;
    final needsCloud =
        scope.cloudSync.cloudBackupEnabled &&
        scope.cloudSync.isSignedIn &&
        (scope.library.contentDirtySinceBackup ||
            scope.cloudSync.pendingCloudBackup);
    if (needsCloud) {
      await scope.cloudSync.markPendingCloudBackup();
    }
    if (!mounted) return;
    final scheduled = await MobileBackgroundBackup.scheduleIfNeeded(
      contentDirty:
          scope.library.contentDirtySinceBackup ||
          scope.cloudSync.pendingCloudBackup,
      cloudBackupEnabled: scope.cloudSync.cloudBackupEnabled,
      isSignedIn: scope.cloudSync.isSignedIn,
      autoBackupEnabled: scope.backup.autoBackupEnabled,
      isReadOnly: scope.library.isReadOnly,
    );
    if (!scheduled) return;
    _leaveBackupScheduled = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(AndroidLeaveBackup.clearUserLeavingListener());
    final library = _library;
    if (library != null) {
      library.removeListener(_reportSaveError);
      unawaited(library.flushPending().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _handlingExit,
          child: PopScope(
            canPop: WindowChrome.isDesktop,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (scope.quickToolbar.handleAuxiliaryPanelBack?.call() ==
                  true) {
                return;
              }
              unawaited(_onRootBack());
            },
            child: ListenableBuilder(
              listenable: Listenable.merge([
                scope.library,
                scope.theme,
                scope.editorPreferences,
              ]),
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
                    final compact = ZephyrBreakpoints.isCompact(
                      constraints.maxWidth,
                    );
                    if (compact) {
                      final drawerWidth = WorkspaceLayout.mobileDrawerWidth
                          .clamp(260.0, constraints.maxWidth * 0.88);
                      final immersive = immersiveStatusBar;
                      final editorBackground = scope.theme.ui
                          .activeEditorBackgroundFor(
                            dark: scope.theme.isEffectivelyDark,
                          );
                      final bleedEditorBackground = editorBackground.hasImage;
                      // Bleed under the status band when immersive or a writing-column
                      // background is active so the image fills above the book bar.
                      final invadeStatusBand =
                          immersive || bleedEditorBackground;
                      final sidebarColor = Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest;
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
                                top: !invadeStatusBand,
                                // Content paints under the transparent gesture bar.
                                bottom: false,
                                child: Column(
                                  children: [
                                    if (model.needsLibrarySetup)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: invadeStatusBand
                                              ? zephyrTopInset(context)
                                              : 0,
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
                                          invadeStatusBar: invadeStatusBand,
                                          transparentTopBar:
                                              bleedEditorBackground,
                                          openSettings: _openSettings,
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

                    final editorBackground = scope.theme.ui
                        .activeEditorBackgroundFor(
                          dark: scope.theme.isEffectivelyDark,
                        );
                    // Desktop: paint the writing-column image behind the title bar and
                    // under the resize grip so expanding the sidebar does not leave a
                    // solid strip beside the photo.
                    final bleedEditorBackground = editorBackground.hasImage;
                    final workspace = Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedContainer(
                          duration: model.isResizingSidebar
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: model.isSidebarExpanded
                              ? model.sidebarWidth
                              : 0,
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
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (bleedEditorBackground)
                                ListenableBuilder(
                                  listenable: scope.theme,
                                  builder: (context, _) =>
                                      EditorBackgroundLayer(
                                        config: scope.theme.ui
                                            .activeEditorBackgroundFor(
                                              dark:
                                                  scope.theme.isEffectivelyDark,
                                            ),
                                        child: const SizedBox.expand(),
                                      ),
                                ),
                              Column(
                                children: [
                                  if (model.needsLibrarySetup)
                                    _LibrarySetupBanner(
                                      openLibrary: _openLibrary,
                                    ),
                                  WorkspaceHeader(
                                    model: model,
                                    showSidebarToggle: !model.isSidebarExpanded,
                                    showDocumentTitle: _showTitleInChrome,
                                    dimDocumentTitle: scope
                                        .editorPreferences
                                        .preferences
                                        .typewriterMode,
                                    transparent: bleedEditorBackground,
                                    toolsBuilder: (headerContext) =>
                                        buildWorkspaceOverflowTools(
                                          headerContext,
                                          model: model,
                                          openSettings: _openSettings,
                                        ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (model.isSidebarExpanded)
                                          SidebarResizeHandle(
                                            model: model,
                                            maxWidth: _maxSidebarWidth(
                                              constraints.maxWidth,
                                            ),
                                          ),
                                        Expanded(
                                          child: WorkspaceEditor(
                                            model: model,
                                            preferences:
                                                scope.editorPreferences,
                                            showBackground:
                                                !bleedEditorBackground,
                                            onDocumentTitleObscured:
                                                (obscured) {
                                                  if (_showTitleInChrome ==
                                                      obscured) {
                                                    return;
                                                  }
                                                  setState(
                                                    () => _showTitleInChrome =
                                                        obscured,
                                                  );
                                                },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: const CloudBackupQuickButton(
                                  iconSize: 16,
                                  hoverBorder: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    // Floating settings: overlays the workspace without resizing the
                    // sidebar slot or the editor.
                    final settingsInset =
                        WorkspaceLibraryDockMetrics.horizontalInset;
                    final settingsPanelWidth = math.max(
                      WorkspaceSettingsPanel.preferredWidth,
                      model.sidebarWidth - 2 * settingsInset,
                    );
                    final settingsStackHeight = math.max(
                      0.0,
                      constraints.maxHeight -
                          WorkspaceHeader.height -
                          WorkspaceBookPicker.blockHeight,
                    );
                    final settingsPanelHeight = settingsStackHeight * 2 / 3;
                    final shell = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        workspace,
                        if (_settingsOpen)
                          Focus(
                            autofocus: true,
                            onKeyEvent: (node, event) {
                              final action = scope.keyboardShortcuts
                                  .actionForKeyEvent(event);
                              if (action == ShortcutActionId.closeSettings) {
                                _closeSettings();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: _closeSettings,
                                    behavior: HitTestBehavior.opaque,
                                    child: const ColoredBox(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: settingsInset,
                                  bottom:
                                      WorkspaceLibraryDockMetrics.settingsBottomInset(
                                        context,
                                      ),
                                  width: settingsPanelWidth,
                                  height: settingsPanelHeight,
                                  child: WorkspaceSettingsSlideIn(
                                    child: WorkspaceSettingsPanel(
                                      onClose: _closeSettings,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
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
            ),
          ),
        ),
        if (_handlingExit)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: 0.88),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(context.l10n.exitBackupInProgress),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openLibrary() async {
    final scope = ZephyrScope.of(context);
    if (scope.cloudSync.busy) {
      ZephyrSnackBar.show(
        context,
        context.l10n.cloudSyncWaitBeforeChoosingDirectory,
      );
      return;
    }
    final picked = await _pickLibraryFolder();
    if (picked != null && mounted) {
      if (scope.cloudSync.busy) {
        ZephyrSnackBar.show(
          context,
          context.l10n.cloudSyncWaitBeforeChoosingDirectory,
        );
        return;
      }
      await scope.library.openLibrary(picked.path, bookmark: picked.bookmark);
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
    required this.openSettings,
    this.invadeStatusBar = false,
    this.transparentTopBar = false,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;
  final VoidCallback openSettings;

  /// When true, the editor extends under the status band so scrolled text can
  /// enter it naturally. Top-bar show/hide never changes scroll padding.
  final bool invadeStatusBar;

  /// Clear the floating book bar fill so the editor background shows through.
  final bool transparentTopBar;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final toolbar = ZephyrScope.of(context).quickToolbar;
    _editorBridge.onDismissToolsPanel = () {
      if (!toolbar.toolsDrawerOpen &&
          !toolbar.formatDrawerOpen &&
          !toolbar.holdingPanelForIme) {
        return;
      }
      toolbar.closeToolsDrawer();
      toolbar.closeFormatDrawer();
    };
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
          child: Opacity(opacity: (1.0 - t).clamp(0.0, 1.0), child: child),
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
    final statusTop = widget.invadeStatusBar ? zephyrTopInset(context) : 0.0;
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
      child: AnimatedBuilder(
        animation: _hide,
        builder: (context, _) {
          // Match the opaque-band fade: while the bar is visible, hide text
          // above its bottom edge; as it hides, release the clip.
          final textClipTop = widget.transparentTopBar
              ? barBottom * (1.0 - _hide.value)
              : 0.0;
          return Stack(
            children: [
              if (widget.transparentTopBar)
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: themeVm,
                    builder: (context, _) => EditorBackgroundLayer(
                      config: themeVm.ui.activeEditorBackgroundFor(
                        dark: themeVm.isEffectivelyDark,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              Positioned.fill(
                child: ClipRect(
                  clipper: textClipTop > 0.5
                      ? _TopExcludeClipper(textClipTop)
                      : null,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([widget.preferences, themeVm]),
                    builder: (context, _) => QuickToolbarHost(
                      toolbar: quickToolbar,
                      bridge: _editorBridge,
                      foreground: foreground,
                      editorPreferences: widget.preferences,
                      bodyFontFamily: widget.preferences.preferences.fontFamily,
                      hidden: themeVm.ui.hideQuickToolbar,
                      child: WorkspaceEditor(
                        model: widget.model,
                        preferences: widget.preferences,
                        contentTopInset: contentTop,
                        showWordCount: false,
                        bridge: _editorBridge,
                        showBackground: !widget.transparentTopBar,
                      ),
                    ),
                  ),
                ),
              ),
              // Opaque band above the bar when there is no background image.
              if (!widget.transparentTopBar)
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
                    transparentBackground: widget.transparentTopBar,
                    toolsBuilder: (barContext) => buildWorkspaceOverflowTools(
                      barContext,
                      model: widget.model,
                      openSettings: widget.openSettings,
                    ),
                  ),
                ),
              ),
              if (wordCount != null)
                Positioned(
                  // Below the book bar, top-right of the reading area.
                  top: statusTop + _barTravel,
                  right: 8,
                  child: _wordCountFade(
                    child: ListenableBuilder(
                      listenable: _editorBridge,
                      builder: (context, _) {
                        final controller = _editorBridge.controller;
                        final focusNode = _editorBridge.focusNode;
                        if (controller == null || focusNode == null) {
                          return EditorOverlayCapsule(
                            compact: true,
                            child: Text(
                              '$wordCount',
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.2,
                                color: EditorOverlayCapsule.foregroundOf(
                                  context,
                                ),
                              ),
                            ),
                          );
                        }
                        return EditorWordCountChip(
                          controller: controller,
                          focusNode: focusNode,
                          fallbackTotal: wordCount,
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Clips away the top [excludeHeight] so text cannot paint under the book bar,
/// while a separate full-bleed background layer remains visible.
class _TopExcludeClipper extends CustomClipper<Rect> {
  const _TopExcludeClipper(this.excludeHeight);

  final double excludeHeight;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, excludeHeight, size.width, size.height);

  @override
  bool shouldReclip(covariant _TopExcludeClipper oldClipper) =>
      oldClipper.excludeHeight != excludeHeight;
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
  const _LibrarySetupPage({required this.openLibrary, this.error});

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

/// Shared overflow tools for the mobile top-bar more menu and desktop
/// title-bar more button (left of the caption minimize control).
List<WorkspaceMobileTool> buildWorkspaceOverflowTools(
  BuildContext context, {
  required LibraryViewModel model,
  required VoidCallback openSettings,
}) {
  final l10n = context.l10n;
  final scope = ZephyrScope.of(context);
  final themeVm = scope.theme;
  final backup = scope.backup;
  return [
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.search,
      icon: Icons.search,
      label: l10n.tooltipSearchChapters,
      onTap: () => unawaited(showLibrarySearchSheet(context, model: model)),
    ),
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.themeMode,
      icon: Icons.brightness_6_outlined,
      label: l10n.mobileToolThemeMode,
      onTap: () => unawaited(_pickMobileThemeMode(context, themeVm)),
      submenu: [
        WorkspaceOverflowSubmenuChoice(
          id: AppThemeMode.system.name,
          label: l10n.themeModeSystem,
          selected: themeVm.themeMode == AppThemeMode.system,
          onSelected: () => themeVm.setThemeMode(AppThemeMode.system),
        ),
        WorkspaceOverflowSubmenuChoice(
          id: AppThemeMode.light.name,
          label: l10n.themeModeLight,
          selected: themeVm.themeMode == AppThemeMode.light,
          onSelected: () => themeVm.setThemeMode(AppThemeMode.light),
        ),
        WorkspaceOverflowSubmenuChoice(
          id: AppThemeMode.dark.name,
          label: l10n.themeModeDark,
          selected: themeVm.themeMode == AppThemeMode.dark,
          onSelected: () => themeVm.setThemeMode(AppThemeMode.dark),
        ),
      ],
    ),
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.switchTheme,
      icon: Icons.palette_outlined,
      label: l10n.mobileToolSwitchTheme,
      onTap: () => unawaited(_pickMobileThemePack(context, themeVm)),
      submenu: [
        for (final pack in themeVm.colorPacks)
          WorkspaceOverflowSubmenuChoice(
            id: pack.id,
            label: _mobileThemePackTitle(l10n, pack),
            selected: themeVm.activePackId == pack.id,
            onSelected: () => themeVm.applyPack(pack.id),
          ),
      ],
    ),
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.backup,
      icon: Icons.backup_outlined,
      label: l10n.quickToolbarBackupTooltip,
      enabled: !backup.busy,
      onTap: () => unawaited(_overflowBackupNow(context)),
    ),
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.restore,
      icon: Icons.restore_rounded,
      label: l10n.quickToolbarRestoreTooltip,
      enabled: !backup.busy && backup.backups.isNotEmpty,
      onTap: () => unawaited(showBackupRestoreFlow(context, backup)),
    ),
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.settings,
      icon: Icons.settings_outlined,
      label: l10n.tooltipSettings,
      onTap: openSettings,
    ),
  ];
}

Future<void> _overflowBackupNow(BuildContext context) async {
  final backup = ZephyrScope.of(context).backup;
  final l10n = context.l10n;
  await backup.backupNow();
  if (!context.mounted) return;
  final error = backup.error;
  ZephyrSnackBar.show(
    context,
    error == null ? l10n.backupNowSuccess : l10n.backupFailed(error.toString()),
  );
}

Future<void> _pickMobileThemeMode(
  BuildContext context,
  ThemeViewModel themeVm,
) async {
  final l10n = context.l10n;
  final next = await showZephyrSettingsChoicePicker<AppThemeMode>(
    context,
    title: l10n.themeModeTitle,
    selected: themeVm.themeMode,
    choices: [
      ZephyrSettingsChoice(
        value: AppThemeMode.system,
        label: l10n.themeModeSystem,
      ),
      ZephyrSettingsChoice(
        value: AppThemeMode.light,
        label: l10n.themeModeLight,
      ),
      ZephyrSettingsChoice(value: AppThemeMode.dark, label: l10n.themeModeDark),
    ],
  );
  if (next == null) return;
  themeVm.setThemeMode(next);
}

Future<void> _pickMobileThemePack(
  BuildContext context,
  ThemeViewModel themeVm,
) async {
  final l10n = context.l10n;
  final next = await showZephyrSettingsChoicePicker<String>(
    context,
    title: l10n.themePresetsSectionTitle,
    selected: themeVm.activePackId,
    choices: [
      for (final pack in themeVm.colorPacks)
        ZephyrSettingsChoice(
          value: pack.id,
          label: _mobileThemePackTitle(l10n, pack),
        ),
    ],
  );
  if (next == null) return;
  themeVm.applyPack(next);
}

String _mobileThemePackTitle(AppLocalizations l10n, ThemeColorPack pack) {
  final preset = pack.builtInPreset;
  if (preset == null) return pack.name;
  return switch (preset) {
    ThemePreset.light => l10n.themePresetLight,
    ThemePreset.grey => l10n.themePresetGrey,
    ThemePreset.slate => l10n.themePresetSlate,
    ThemePreset.claude => l10n.themePresetClaude,
    ThemePreset.mint => l10n.themePresetMint,
    ThemePreset.purple => l10n.themePresetPurple,
    ThemePreset.hermes => l10n.themePresetHermes,
    ThemePreset.ocean => l10n.themePresetOcean,
    ThemePreset.darkModern => l10n.themePresetDarkModern,
  };
}
