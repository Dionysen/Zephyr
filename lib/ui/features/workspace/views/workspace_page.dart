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
import '../../../../domain/models/purewriter_models.dart';
import '../../../../domain/models/theme_color_pack.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/workspace_layout.dart';

import '../../../core/breakpoints.dart';
import '../../../core/editor_background_layer.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_dialog.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_dual_editor_pager.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_snackbar.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/quick_toolbar/quick_toolbar_host.dart';
import '../../editor/quick_toolbar/workspace_editor_bridge.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../settings/view_models/theme_view_model.dart';
import '../../settings/views/backup_settings_view.dart';
import '../../settings/models/settings_tab.dart';
import '../../settings/views/settings_page.dart';
import 'cloud_backup_quick_button.dart';
import 'library_search_sheet.dart';
import '../models/workspace_ai_context_selection.dart';
import 'workspace_ai_chat_view.dart';
import 'desktop_floating_sidebar.dart';
import 'workspace_cloud_backup_shortcut.dart';
import 'workspace_editor.dart';
import 'workspace_mobile_body_host.dart';
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

  var _desktopAiChatOpen = false;
  final _desktopAiContext = WorkspaceAiContextSelection();
  String? _desktopBookId;
  ThemeViewModel? _themeVm;
  bool? _lastAiFeaturesEnabled;

  /// Avoid enqueueing leave backup twice across leave-hint → paused → detached.
  var _leaveBackupScheduled = false;

  /// Root back is exiting after scheduling background backup.
  var _handlingExit = false;
  DateTime? _lastRootBackPress;
  Object? _leaveBackupError;
  Object? _reportedSaveError;

  var _desktopFloatingSidebarOpen = false;
  bool? _lastDesktopFloatingSidebarPref;
  final _editorChromeFocusNode = FocusScopeNode();
  ZephyrDualEditorPagerController? _mobilePagerController;

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
    _attachThemeAiListener();
    _library = ZephyrScope.of(context).library;
    if (_started) {
      return;
    }
    _started = true;
    _library!
      ..addListener(_reportSaveError)
      ..addListener(_onDesktopBookChanged);
    _desktopBookId = _library!.selectedBook?.id;
    unawaited(_bootstrapLibrary());
  }

  void _attachThemeAiListener() {
    final theme = ZephyrScope.of(context).theme;
    if (_themeVm == theme) return;
    _themeVm?.removeListener(_onThemeAiPreferenceChanged);
    _themeVm = theme;
    _lastAiFeaturesEnabled = theme.ui.aiFeaturesEnabled;
    _lastDesktopFloatingSidebarPref = theme.ui.desktopFloatingSidebar;
    _themeVm!.addListener(_onThemeAiPreferenceChanged);
  }

  void _onThemeAiPreferenceChanged() {
    if (!mounted || _themeVm == null) return;
    final ui = _themeVm!.ui;
    var needsSetState = false;
    if (_lastAiFeaturesEnabled != ui.aiFeaturesEnabled) {
      _lastAiFeaturesEnabled = ui.aiFeaturesEnabled;
      needsSetState = true;
      if (!ui.aiFeaturesEnabled) _desktopAiChatOpen = false;
    }
    if (_lastDesktopFloatingSidebarPref != ui.desktopFloatingSidebar) {
      _lastDesktopFloatingSidebarPref = ui.desktopFloatingSidebar;
      needsSetState = true;
      if (ui.desktopFloatingSidebar) {
        _library?.collapseSidebar();
        _desktopFloatingSidebarOpen = false;
      }
    }
    if (needsSetState) setState(() {});
  }

  void _onDesktopBookChanged() {
    final id = _library?.selectedBook?.id;
    if (id == _desktopBookId) return;
    _desktopBookId = id;
    _desktopAiContext.clear();
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
    if (library.recoveredToTemporaryLibrary) {
      library.clearRecoveredToTemporaryLibraryNotice();
      ZephyrSnackBar.show(context, context.l10n.libraryRecoveredToTemporary);
    }
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
      final action = await showZephyrDialog<String>(
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

    final scope = ZephyrScope.of(context);
    if (scope.theme.ui.doubleBackToExit) {
      final now = DateTime.now();
      final last = _lastRootBackPress;
      if (last == null || now.difference(last) > const Duration(seconds: 2)) {
        _lastRootBackPress = now;
        ZephyrSnackBar.show(context, context.l10n.pressBackAgainToExit);
        return;
      }
    }

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
      library
        ..removeListener(_reportSaveError)
        ..removeListener(_onDesktopBookChanged);
      unawaited(library.flushPending().catchError((Object _) {}));
    }
    _themeVm?.removeListener(_onThemeAiPreferenceChanged);
    _editorChromeFocusNode.dispose();
    _desktopAiContext.dispose();
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
              if (scope.quickToolbar.handleAuxiliaryPanelBack?.call() == true) {
                return;
              }
              final pager = _mobilePagerController;
              if (!WindowChrome.isDesktop &&
                  pager != null &&
                  pager.drawersOpen) {
                pager.closeDrawers();
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
                      startTemporaryLibrary: () =>
                          model.startWithTemporaryLibrary(),
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
                                      child: _MobileTwoEditorWorkspace(
                                        model: model,
                                        preferences: scope.editorPreferences,
                                        drawerWidth: drawerWidth,
                                        sidebarColor: sidebarColor,
                                        sidebarTopInset: immersive,
                                        invadeStatusBar: invadeStatusBand,
                                        transparentTopBar:
                                            bleedEditorBackground,
                                        openLibrary: _openLibrary,
                                        openSettings: _openSettings,
                                        onMobilePagerController: (controller) {
                                          _mobilePagerController = controller;
                                        },
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
                    final aiFeaturesEnabled = scope.theme.ui.aiFeaturesEnabled;
                    final desktopAiChatVisible =
                        aiFeaturesEnabled && _desktopAiChatOpen;
                    final desktopAiImmersiveBleed =
                        immersiveStatusBar && desktopAiChatVisible;
                    final desktopColumnBleed =
                        bleedEditorBackground || desktopAiImmersiveBleed;
                    final desktopFloatingSidebar =
                        scope.theme.ui.desktopFloatingSidebar;
                    final dockedSidebarVisible =
                        !desktopFloatingSidebar && model.isSidebarExpanded;
                    final workspace = Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedContainer(
                          duration: model.isResizingSidebar
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: dockedSidebarVisible
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
                                aiContextEnabled: desktopAiChatVisible,
                                aiContext: _desktopAiContext,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FocusScope(
                            node: _editorChromeFocusNode,
                            onFocusChange: (focused) {
                              if (!desktopFloatingSidebar ||
                                  !_desktopFloatingSidebarOpen) {
                                return;
                              }
                              if (focused) {
                                setState(
                                  () => _desktopFloatingSidebarOpen = false,
                                );
                              }
                            },
                            child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (desktopColumnBleed)
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
                                    showSidebarToggle: desktopFloatingSidebar
                                        ? !_desktopFloatingSidebarOpen
                                        : !model.isSidebarExpanded,
                                    onSidebarToggle: desktopFloatingSidebar
                                        ? () => setState(
                                            () => _desktopFloatingSidebarOpen =
                                                !_desktopFloatingSidebarOpen,
                                          )
                                        : null,
                                    showDocumentTitle: _showTitleInChrome,
                                    dimDocumentTitle: scope
                                        .editorPreferences
                                        .preferences
                                        .typewriterMode,
                                    transparent: desktopAiChatVisible
                                        ? desktopColumnBleed
                                        : bleedEditorBackground,
                                    aiActive: desktopAiChatVisible,
                                    onAiPressed: aiFeaturesEnabled
                                        ? _toggleDesktopAiChat
                                        : null,
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
                                        if (dockedSidebarVisible)
                                          SidebarResizeHandle(
                                            model: model,
                                            maxWidth: _maxSidebarWidth(
                                              constraints.maxWidth,
                                            ),
                                          ),
                                        Expanded(
                                          child: desktopAiChatVisible
                                              ? WorkspaceAiChatView(
                                                  bleedEditorBackground:
                                                      desktopColumnBleed,
                                                  contextSelection:
                                                      _desktopAiContext,
                                                  libraryModel: model,
                                                  onOpenDesktopAiSettings:
                                                      _openDesktopAiSettings,
                                                )
                                              : WorkspaceEditor(
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
                                                          () =>
                                                              _showTitleInChrome =
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
                              if (!desktopAiChatVisible)
                                const Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: CloudBackupQuickButton(
                                    iconSize: 16,
                                    hoverBorder: true,
                                  ),
                                ),
                            ],
                          ),
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
                        if (desktopFloatingSidebar && !desktopAiChatVisible)
                          DesktopFloatingSidebar(
                            model: model,
                            open: _desktopFloatingSidebarOpen,
                            onOpenChanged: (open) {
                              if (_desktopFloatingSidebarOpen == open) return;
                              setState(() => _desktopFloatingSidebarOpen = open);
                            },
                            maxSidebarWidth: _maxSidebarWidth(
                              constraints.maxWidth,
                            ),
                            openLibrary: _openLibrary,
                            openSettings: _openSettings,
                            aiContextEnabled: desktopAiChatVisible,
                            aiContext: _desktopAiContext,
                          ),
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
                              final cloud = handleCloudBackupShortcut(
                                context,
                                event,
                              );
                              if (cloud != null) return cloud;
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
    setState(() {
      _settingsOpen = !_settingsOpen;
      if (_settingsOpen) _desktopFloatingSidebarOpen = false;
    });
    if (_settingsOpen) {
      prefetchWorkspaceSettingsFonts(context);
    }
  }

  /// Same floating panel as the sidebar settings button, on the AI tab.
  void _openDesktopAiSettings() {
    ZephyrScope.of(context).settings.selectTab(SettingsTab.ai);
    if (_settingsOpen) return;
    setState(() => _settingsOpen = true);
    prefetchWorkspaceSettingsFonts(context);
  }

  void _closeSettings() {
    if (!_settingsOpen) {
      return;
    }
    setState(() => _settingsOpen = false);
  }

  void _toggleDesktopAiChat() {
    if (!ZephyrScope.of(context).theme.ui.aiFeaturesEnabled) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _desktopAiChatOpen = !_desktopAiChatOpen);
  }

  double _maxSidebarWidth(double workspaceWidth) {
    final available = workspaceWidth - 360 - SidebarResizeHandle.width;
    return available.clamp(
      LibraryViewModel.minSidebarWidth,
      LibraryViewModel.maxSidebarWidth,
    );
  }
}

/// Compact workspace with two independent book/editor sessions.
///
/// The primary session remains the application-wide library owner. A second
/// view model shares its repository but owns its own book, chapter, caret and
/// scroll state. Its writes are registered with the primary session so the
/// existing flush, backup, and cloud-dirty guarantees still cover both pages.
class _MobileTwoEditorWorkspace extends StatefulWidget {
  const _MobileTwoEditorWorkspace({
    required this.model,
    required this.preferences,
    required this.drawerWidth,
    required this.sidebarColor,
    required this.sidebarTopInset,
    required this.invadeStatusBar,
    required this.transparentTopBar,
    required this.openLibrary,
    required this.openSettings,
    required this.onMobilePagerController,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;
  final double drawerWidth;
  final Color sidebarColor;
  final bool sidebarTopInset;
  final bool invadeStatusBar;
  final bool transparentTopBar;
  final Future<void> Function() openLibrary;
  final VoidCallback openSettings;
  final ValueChanged<ZephyrDualEditorPagerController?> onMobilePagerController;

  @override
  State<_MobileTwoEditorWorkspace> createState() =>
      _MobileTwoEditorWorkspaceState();
}

/// Publishes [ZephyrDualEditorPagerController] to the workspace root back handler.
class _MobilePagerControllerBinder extends StatefulWidget {
  const _MobilePagerControllerBinder({
    required this.onAttached,
    required this.child,
  });

  final ValueChanged<ZephyrDualEditorPagerController?> onAttached;
  final Widget child;

  @override
  State<_MobilePagerControllerBinder> createState() =>
      _MobilePagerControllerBinderState();
}

class _MobilePagerControllerBinderState
    extends State<_MobilePagerControllerBinder> {
  @override
  void dispose() {
    widget.onAttached(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (inner) {
        widget.onAttached(ZephyrDualEditorPager.maybeOf(inner));
        return widget.child;
      },
    );
  }
}

/// Negative scroll delta while pinned at the list bottom (stretch / settle).
bool _mobileScrollRubberBandAtBottom(ScrollMetrics metrics, double delta) {
  if (delta >= 0) return false;
  final max = metrics.maxScrollExtent;
  if (!max.isFinite) return false;
  return metrics.pixels >= max - 1.0;
}

class _MobileTwoEditorWorkspaceState extends State<_MobileTwoEditorWorkspace>
    with TickerProviderStateMixin {
  static const _barInset = 8.0;
  static const _barSideInset = 12.0;
  static const _barGapBelow = 6.0;
  static const _barHideSlop = 36.0;
  static const _barMotion = Cubic(0.2, 0.0, 0.0, 1.0);

  late final LibraryViewModel _companion;
  final _primaryBridge = WorkspaceEditorBridge();
  final _companionBridge = WorkspaceEditorBridge();
  final _activeEditor = ValueNotifier<int>(0);
  late final AnimationController _topBarHide;
  var _topBarScrollSlop = 0.0;
  var _topBarUserScroll = false;
  var _companionReady = false;
  var _ensuringDistinctBooks = false;
  var _refreshingCompanionSnapshot = false;
  String _primaryStructure = '';
  String _companionStructure = '';
  var _primaryAiChatOpen = false;
  var _companionAiChatOpen = false;
  final _primaryAiContext = WorkspaceAiContextSelection();
  final _companionAiContext = WorkspaceAiContextSelection();
  String? _primaryBookId;
  String? _companionBookId;
  ThemeViewModel? _themeVm;
  bool? _lastAiFeaturesEnabled;

  @override
  void initState() {
    super.initState();
    _topBarHide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _companion = LibraryViewModel(
      widget.model.repository,
      needsLibrarySetup: widget.model.needsLibrarySetup,
    );
    _primaryBookId = widget.model.selectedBook?.id;
    widget.model.addListener(_onPrimaryBookChanged);
    _companion.addListener(_onCompanionBookChanged);
    _companion.onLocalContentPersisted = () async {
      widget.model.markContentDirtyFromCompanion();
      await widget.model.onLocalContentPersisted?.call();
    };
    widget.model.addListener(_onPrimaryChanged);
    _companion.addListener(_onCompanionChanged);
    unawaited(_initializeCompanion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachThemeAiListener();
    final toolbar = ZephyrScope.of(context).quickToolbar;
    void dismissToolsPanel() {
      if (!toolbar.toolsDrawerOpen &&
          !toolbar.formatDrawerOpen &&
          !toolbar.holdingPanelForIme) {
        return;
      }
      toolbar.closeToolsDrawer();
      toolbar.closeFormatDrawer();
    }

    _primaryBridge.onDismissToolsPanel = dismissToolsPanel;
    _companionBridge.onDismissToolsPanel = dismissToolsPanel;
  }

  void _attachThemeAiListener() {
    final theme = ZephyrScope.of(context).theme;
    if (_themeVm == theme) return;
    _themeVm?.removeListener(_onThemeAiPreferenceChanged);
    _themeVm = theme;
    _lastAiFeaturesEnabled = theme.ui.aiFeaturesEnabled;
    _themeVm!.addListener(_onThemeAiPreferenceChanged);
  }

  void _onThemeAiPreferenceChanged() {
    if (!mounted || _themeVm == null) return;
    final enabled = _themeVm!.ui.aiFeaturesEnabled;
    if (_lastAiFeaturesEnabled == enabled) return;
    _lastAiFeaturesEnabled = enabled;
    setState(() {
      if (!enabled) {
        _primaryAiChatOpen = false;
        _companionAiChatOpen = false;
      }
    });
  }

  void _onPrimaryBookChanged() {
    final id = widget.model.selectedBook?.id;
    if (id == _primaryBookId) return;
    _primaryBookId = id;
    _primaryAiContext.clear();
  }

  void _onCompanionBookChanged() {
    final id = _companion.selectedBook?.id;
    if (id == _companionBookId) return;
    _companionBookId = id;
    _companionAiContext.clear();
  }

  @override
  void dispose() {
    widget.model
      ..removeListener(_onPrimaryChanged)
      ..removeListener(_onPrimaryBookChanged)
      ..flushMobileCompanion = null
      ..markMobileCompanionBackupCompleted = null;
    _companion
      ..removeListener(_onCompanionChanged)
      ..removeListener(_onCompanionBookChanged);
    _primaryAiContext.dispose();
    _companionAiContext.dispose();
    _primaryBridge.dispose();
    _companionBridge.dispose();
    _activeEditor.dispose();
    _topBarHide.dispose();
    _themeVm?.removeListener(_onThemeAiPreferenceChanged);
    _companion.dispose();
    super.dispose();
  }

  Future<void> _initializeCompanion() async {
    await _companion.load();
    if (!mounted) return;
    await _restoreCompanionSelection();
    if (!mounted) return;
    _companionBookId = _companion.selectedBook?.id;
    _primaryStructure = _structureOf(widget.model);
    _companionStructure = _structureOf(_companion);
    widget.model
      ..flushMobileCompanion = _companion.flushPending
      ..markMobileCompanionBackupCompleted = _companion.markBackupCompleted;
    _companionReady = true;
    _persistCompanionSelection();
    setState(() {});
  }

  Future<void> _restoreCompanionSelection() async {
    final library = widget.model.library;
    if (library == null) return;
    final primaryBookId = widget.model.selectedBook?.id;
    final storedBookId = widget.model.mobileCompanionBookId;
    final storedArticleId = widget.model.mobileCompanionArticleId;
    final storedBookExists = library.folders.any(
      (book) => book.id == storedBookId && !book.isTrash,
    );
    final preferredBookId = storedBookExists && storedBookId != primaryBookId
        ? storedBookId
        : _nextWritableBookId(after: primaryBookId);
    if (preferredBookId != null) {
      await _companion.selectBook(preferredBookId);
    }
    final storedArticleExists = library.articles.any(
      (article) =>
          article.id == storedArticleId &&
          article.folderId == _companion.selectedBook?.id,
    );
    if (storedArticleExists) {
      await _companion.selectArticle(storedArticleId!);
    }
  }

  String? _nextWritableBookId({required String? after}) {
    final List<WritingFolder> books =
        widget.model.library?.folders
            .where((book) => !book.isTrash)
            .toList(growable: false) ??
        const [];
    if (books.isEmpty) return null;
    final currentIndex = books.indexWhere((book) => book.id == after);
    if (currentIndex >= 0 && books.length > 1) {
      return books[(currentIndex + 1) % books.length].id;
    }
    return books.first.id;
  }

  String _structureOf(LibraryViewModel model) {
    final library = model.library;
    if (library == null) return '';
    return [
      for (final book in library.folders) book.id,
      for (final volume in library.categories) volume.id,
      for (final article in library.articles) article.id,
    ].join('|');
  }

  void _onPrimaryChanged() {
    final structure = _structureOf(widget.model);
    if (structure != _primaryStructure) {
      _primaryStructure = structure;
      if (_companionReady) unawaited(_refreshCompanionSnapshot());
    }
    if (_companionReady) unawaited(_ensureDistinctBooks());
  }

  void _onCompanionChanged() {
    if (_companion.contentDirtySinceBackup) {
      widget.model.markContentDirtyFromCompanion();
    }
    if (_companionReady) {
      _persistCompanionSelection();
      final structure = _structureOf(_companion);
      if (structure != _companionStructure) {
        _companionStructure = structure;
        unawaited(widget.model.load());
      }
    }
  }

  Future<void> _refreshCompanionSnapshot() async {
    if (_refreshingCompanionSnapshot) return;
    _refreshingCompanionSnapshot = true;
    try {
      await _companion.load();
      if (mounted) await _ensureDistinctBooks();
    } finally {
      _refreshingCompanionSnapshot = false;
    }
  }

  Future<void> _ensureDistinctBooks() async {
    if (_ensuringDistinctBooks || !mounted) return;
    final primaryBookId = widget.model.selectedBook?.id;
    if (primaryBookId == null || _companion.selectedBook?.id != primaryBookId) {
      return;
    }
    final nextBookId = _nextWritableBookId(after: primaryBookId);
    if (nextBookId == null || nextBookId == primaryBookId) return;
    _ensuringDistinctBooks = true;
    try {
      await _companion.selectBook(nextBookId);
    } finally {
      _ensuringDistinctBooks = false;
    }
  }

  void _persistCompanionSelection() {
    widget.model.setMobileCompanionSelection(
      bookId: _companion.selectedBook?.id,
      articleId: _companion.article?.id,
    );
  }

  void _setActiveEditor(int index) {
    if (_activeEditor.value == index) return;
    final toolbar = ZephyrScope.of(context).quickToolbar;
    toolbar.closeToolsDrawer();
    toolbar.closeFormatDrawer();
    _activeEditor.value = index;
  }

  bool _aiChatOpenFor(int editorIndex) =>
      editorIndex == 0 ? _primaryAiChatOpen : _companionAiChatOpen;

  void _toggleAiChatFor(int editorIndex) {
    if (!ZephyrScope.of(context).theme.ui.aiFeaturesEnabled) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      if (editorIndex == 0) {
        _primaryAiChatOpen = !_primaryAiChatOpen;
      } else {
        _companionAiChatOpen = !_companionAiChatOpen;
      }
    });
  }

  bool _onWorkspaceScroll(ScrollNotification notification) {
    if (!ZephyrScope.of(context).theme.ui.scrollToHideMobileTopBar) {
      if (_topBarHide.value > 0) _topBarHide.value = 0;
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification) {
      _topBarUserScroll = notification.dragDetails != null;
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      if (!_topBarUserScroll) return false;
      final delta = notification.scrollDelta;
      if (delta == null || delta == 0) return false;
      if (notification.metrics.pixels <= 0) {
        _topBarScrollSlop = 0;
        _showTopBar();
        return false;
      }
      final direction = delta > 0 ? 1 : -1;
      if (_topBarScrollSlop != 0 && _topBarScrollSlop.sign != direction) {
        _topBarScrollSlop = 0;
      }
      _topBarScrollSlop += delta;
      if (_topBarScrollSlop.abs() >= _barHideSlop) {
        if (direction > 0) {
          _hideTopBar();
        } else if (!_mobileScrollRubberBandAtBottom(
          notification.metrics,
          delta,
        )) {
          _showTopBar();
        }
      }
    } else if (notification is ScrollEndNotification) {
      _topBarUserScroll = false;
      _topBarScrollSlop = 0;
      if (notification.metrics.pixels <= 0) _showTopBar();
    }
    return false;
  }

  void _showTopBar() {
    _topBarScrollSlop = 0;
    if (_topBarHide.value > 0) _topBarHide.animateTo(0, curve: _barMotion);
  }

  void _hideTopBar() {
    _topBarScrollSlop = 0;
    if (_topBarHide.value < 1) _topBarHide.animateTo(1, curve: _barMotion);
  }

  Widget _fixedTopBar(BuildContext pagerContext) {
    final statusTop = widget.invadeStatusBar ? zephyrTopInset(context) : 0.0;
    final travel = _barInset + WorkspaceMobileBookBar.height + _barGapBelow;
    return Positioned(
      top: statusTop + _barInset,
      left: _barSideInset,
      right: _barSideInset,
      child: AnimatedBuilder(
        animation: _topBarHide,
        builder: (context, child) {
          final hidden = _topBarHide.value;
          return IgnorePointer(
            ignoring: hidden > 0.85,
            child: Opacity(
              opacity: (1 - hidden).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -travel * hidden),
                child: child,
              ),
            ),
          );
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _activeEditor,
          builder: (context, activeEditor, _) {
            final model = activeEditor == 0 ? widget.model : _companion;
            final aiEnabled = ZephyrScope.of(context)
                .theme
                .ui
                .aiFeaturesEnabled;
            return WorkspaceMobileBookBar(
              model: model,
              onOpenMenu: () {
                final pager = ZephyrDualEditorPager.of(pagerContext);
                activeEditor == 0
                    ? pager.openStartDrawer()
                    : pager.openEndDrawer();
              },
              reverse: activeEditor == 1,
              transparentBackground: widget.transparentTopBar,
              aiActive: aiEnabled && _aiChatOpenFor(activeEditor),
              onAiPressed: aiEnabled
                  ? () => _toggleAiChatFor(activeEditor)
                  : null,
              toolsBuilder: (barContext) => buildWorkspaceOverflowTools(
                barContext,
                model: model,
                openSettings: widget.openSettings,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _drawerFor(
    LibraryViewModel model, {
    required bool aiContextEnabled,
    required WorkspaceAiContextSelection aiContext,
  }) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Material(
      color: widget.sidebarColor,
      child: NotificationListener<ScrollNotification>(
        // Library drawer scroll must not drive the editor floating top bar.
        onNotification: (_) => true,
        child: ZephyrTopSafeArea(
          top: widget.sidebarTopInset,
          bottom: false,
          left: false,
          right: false,
          child: model.library == null
              ? const Center(child: CircularProgressIndicator())
              : WorkspaceSidebar(
                  model: model,
                  mode: SidebarMode.drawer,
                  openLibrary: widget.openLibrary,
                  openSettings: widget.openSettings,
                  aiContextEnabled: aiContextEnabled,
                  aiContext: aiContext,
                ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    final themeVm = scope.theme;
    final aiEnabled = themeVm.ui.aiFeaturesEnabled;
    final pinnedEditorBackground = widget.transparentTopBar
        ? ListenableBuilder(
            listenable: themeVm,
            builder: (context, _) => EditorBackgroundLayer(
              config: themeVm.ui.activeEditorBackgroundFor(
                dark: themeVm.isEffectivelyDark,
              ),
              child: const SizedBox.expand(),
            ),
          )
        : null;
    final pager = ZephyrDualEditorPager(
      drawerWidth: widget.drawerWidth,
      onActiveEditorChanged: _setActiveEditor,
      fixedUnderlay: pinnedEditorBackground,
      fixedOverlay: Builder(
        builder: (pagerContext) => _fixedTopBar(pagerContext),
      ),
      startDrawer: _drawerFor(
        widget.model,
        aiContextEnabled: aiEnabled && _primaryAiChatOpen,
        aiContext: _primaryAiContext,
      ),
      primaryEditor: Builder(
        builder: (editorContext) => WorkspaceMobileBodyHost(
          model: widget.model,
          child: _MobileEditorChrome(
            model: widget.model,
            preferences: widget.preferences,
            bridge: _primaryBridge,
            onOpenMenu: () =>
                ZephyrDualEditorPager.of(editorContext).openStartDrawer(),
            showBookBar: false,
            sharedTopBarHide: _topBarHide,
            aiChatOpen: aiEnabled && _primaryAiChatOpen,
            aiContextSelection: _primaryAiContext,
            invadeStatusBar: widget.invadeStatusBar,
            transparentTopBar: widget.transparentTopBar,
            openSettings: widget.openSettings,
          ),
        ),
      ),
      companionEditor: ListenableBuilder(
        listenable: _companion,
        builder: (context, _) => Builder(
          builder: (editorContext) => _MobileEditorChrome(
            model: _companion,
            preferences: widget.preferences,
            bridge: _companionBridge,
            onOpenMenu: () =>
                ZephyrDualEditorPager.of(editorContext).openEndDrawer(),
            reverse: true,
            showBookBar: false,
            sharedTopBarHide: _topBarHide,
            aiChatOpen: aiEnabled && _companionAiChatOpen,
            aiContextSelection: _companionAiContext,
            invadeStatusBar: widget.invadeStatusBar,
            transparentTopBar: widget.transparentTopBar,
            openSettings: widget.openSettings,
          ),
        ),
      ),
      endDrawer: _drawerFor(
        _companion,
        aiContextEnabled: aiEnabled && _companionAiChatOpen,
        aiContext: _companionAiContext,
      ),
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _onWorkspaceScroll,
      child: ValueListenableBuilder<int>(
        valueListenable: _activeEditor,
        child: pager,
        builder: (context, activeEditor, pager) => _MobilePagerControllerBinder(
          onAttached: widget.onMobilePagerController,
          child: QuickToolbarHost(
            toolbar: scope.quickToolbar,
            bridge: activeEditor == 0 ? _primaryBridge : _companionBridge,
            library: activeEditor == 0 ? widget.model : _companion,
            foreground: Theme.of(context).colorScheme.onSurface,
            editorPreferences: widget.preferences,
            bodyFontFamily: widget.preferences.preferences.fontFamily,
            hidden: scope.theme.ui.hideQuickToolbar,
            child: pager!,
          ),
        ),
      ),
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
    required this.bridge,
    required this.onOpenMenu,
    this.reverse = false,
    this.showBookBar = true,
    this.aiChatOpen = false,
    this.aiContextSelection,
    this.sharedTopBarHide,
    this.invadeStatusBar = false,
    this.transparentTopBar = false,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;
  final VoidCallback openSettings;
  final WorkspaceEditorBridge bridge;
  final VoidCallback onOpenMenu;
  final bool reverse;
  final bool showBookBar;
  final bool aiChatOpen;
  final WorkspaceAiContextSelection? aiContextSelection;

  /// Floating book bar driven by [_MobileTwoEditorWorkspaceState._topBarHide].
  final Animation<double>? sharedTopBarHide;

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

  /// Accumulated delta before triggering a show/hide jump.
  var _slop = 0.0;
  var _barUserScroll = false;
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
    // AI chat scroll only drives the shared floating bar (workspace listener).
    if (widget.aiChatOpen) return false;
    if (!ZephyrScope.of(context).theme.ui.scrollToHideMobileTopBar) {
      if (!_isVisible) {
        _showBar(immediate: true);
      }
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _barUserScroll = notification.dragDetails != null;
      return false;
    }
    if (notification is ScrollUpdateNotification) {
      if (!_barUserScroll) return false;
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
      } else if (!_mobileScrollRubberBandAtBottom(
        notification.metrics,
        delta,
      )) {
        _showBar();
      }
    } else if (notification is ScrollEndNotification) {
      _barUserScroll = false;
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
    final barBottom = statusTop + _barInset + WorkspaceMobileBookBar.height;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final wordCount = widget.model.article?.wordCount;
    final scope = ZephyrScope.of(context);
    final themeVm = scope.theme;
    final chromeHide = widget.aiChatOpen && widget.sharedTopBarHide != null
        ? widget.sharedTopBarHide!
        : _hide;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: AnimatedBuilder(
        animation: chromeHide,
        builder: (context, _) {
          // Stable top inset while the bar animates (editor and AI chat).
          final contentTop = statusTop + _barTravel;
          final hideT = chromeHide.value;
          final aiBleedsChrome =
              widget.transparentTopBar || widget.invadeStatusBar;
          final paintBleedBackground =
              widget.transparentTopBar ||
              (widget.aiChatOpen && widget.invadeStatusBar);
          // Match the opaque-band fade: while the bar is visible, hide text
          // above its bottom edge; as it hides, release the clip.
          final textClipTop = paintBleedBackground
              ? barBottom * (1.0 - hideT)
              : 0.0;
          return Stack(
            children: [
              if (paintBleedBackground && !widget.transparentTopBar)
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
                  child: widget.aiChatOpen
                      ? WorkspaceAiChatView(
                          contentTopInset: contentTop,
                          bleedEditorBackground: aiBleedsChrome,
                          contextSelection: widget.aiContextSelection,
                          libraryModel: widget.model,
                        )
                      : ListenableBuilder(
                          listenable: Listenable.merge([
                            widget.preferences,
                            themeVm,
                          ]),
                          builder: (context, _) => WorkspaceEditor(
                            model: widget.model,
                            preferences: widget.preferences,
                            contentTopInset: contentTop,
                            showWordCount: false,
                            bridge: widget.bridge,
                            showBackground: !widget.transparentTopBar,
                          ),
                        ),
                ),
              ),
              // Opaque band above the bar when there is no background image.
              if (!widget.transparentTopBar &&
                  !(widget.aiChatOpen && paintBleedBackground))
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
              if (widget.showBookBar)
                Positioned(
                  top: statusTop + _barInset,
                  left: _barSideInset,
                  right: _barSideInset,
                  child: _chromeFade(
                    travel: contentTop,
                    child: WorkspaceMobileBookBar(
                      model: widget.model,
                      onOpenMenu: widget.onOpenMenu,
                      reverse: widget.reverse,
                      transparentBackground: widget.transparentTopBar,
                      aiActive: widget.aiChatOpen,
                      toolsBuilder: (barContext) => buildWorkspaceOverflowTools(
                        barContext,
                        model: widget.model,
                        openSettings: widget.openSettings,
                      ),
                    ),
                  ),
                ),
              if (wordCount != null && !widget.aiChatOpen)
                Positioned(
                  // Below the book bar, top-right of the reading area.
                  top: statusTop + _barTravel,
                  right: 8,
                  child: _wordCountFade(
                    child: ListenableBuilder(
                      listenable: widget.bridge,
                      builder: (context, _) {
                        final controller = widget.bridge.controller;
                        final focusNode = widget.bridge.focusNode;
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
  const _LibrarySetupPage({
    required this.openLibrary,
    required this.startTemporaryLibrary,
    this.error,
  });

  final Object? error;
  final Future<void> Function() openLibrary;
  final Future<void> Function() startTemporaryLibrary;

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
                      l10n.libraryLoadFailedHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => unawaited(startTemporaryLibrary()),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.startTemporaryLibraryButton),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: openLibrary,
                    icon: const Icon(Icons.folder_open_outlined),
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
  final editor = scope.editorPreferences;
  final typewriter = editor.preferences.typewriterMode;
  return [
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.search,
      icon: Icons.search,
      label: l10n.tooltipSearchChapters,
      onTap: () => unawaited(showLibrarySearchSheet(context, model: model)),
    ),
    WorkspaceMobileTool(
      id: WorkspaceMobileToolId.typewriter,
      icon: Icons.vertical_align_center,
      label: l10n.editorTypewriterModeTitle,
      checked: typewriter,
      onTap: () => editor.updateTypewriterMode(!typewriter),
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
