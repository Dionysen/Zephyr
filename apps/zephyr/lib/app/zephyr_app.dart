import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../data/repositories/file_backup_preferences_repository.dart';
import '../data/repositories/file_editor_preferences_repository.dart';
import '../data/repositories/file_keyboard_shortcuts_repository.dart';
import '../data/repositories/file_quick_toolbar_preferences_repository.dart';
import '../data/repositories/file_settings_navigation_repository.dart';
import '../data/repositories/file_system_background_image_repository.dart';
import '../data/repositories/file_system_font_repository.dart';
import '../data/repositories/file_theme_preferences_repository.dart';
import '../data/repositories/file_window_frame_repository.dart';
import '../data/repositories/file_llm_settings_repository.dart';
import '../data/repositories/file_workspace_layout_repository.dart';
import '../data/repositories/purewriter_writing_library_repository.dart';
import '../data/services/backup_preferences_file_storage.dart';
import '../data/services/desktop_backup_notification.dart';
import '../data/services/headless_exit_backup.dart';
import '../data/services/editor_preferences_file_storage.dart';
import '../data/services/keyboard_shortcuts_file_storage.dart';
import '../data/services/purewriter_database.dart';
import '../data/services/quick_toolbar_file_storage.dart';
import '../data/services/settings_navigation_file_storage.dart';
import '../data/services/theme_file_storage.dart';
import '../data/services/window_frame_file_storage.dart';
import '../data/services/workspace_layout_file_storage.dart';
import '../domain/models/ui_preferences.dart';
import '../domain/models/window_frame.dart';
import '../domain/repositories/window_frame_repository.dart';
import '../domain/repositories/workspace_layout_repository.dart';
import '../ui/core/window_chrome.dart';
import '../ui/core/zephyr_controls.dart';
import '../ui/core/zephyr_l10n.dart';
import '../ui/core/zephyr_snackbar.dart';
import '../ui/core/zephyr_scope.dart';
import '../ui/core/zephyr_theme.dart';
import '../ui/features/editor/view_models/editor_preferences_view_model.dart';
import '../ui/features/editor/view_models/library_view_model.dart';
import '../ui/features/editor/quick_toolbar/quick_toolbar_library_sync.dart';
import '../ui/features/editor/view_models/quick_toolbar_view_model.dart';
import '../ui/features/settings/view_models/backup_view_model.dart';
import '../ui/features/settings/view_models/background_image_library.dart';
import '../ui/features/settings/view_models/cloud_sync_view_model.dart';
import '../ui/features/settings/view_models/font_library.dart';
import '../ui/features/settings/view_models/keyboard_shortcuts_view_model.dart';
import '../ui/features/settings/view_models/llm_settings_view_model.dart';
import '../ui/features/settings/view_models/settings_view_model.dart';
import '../ui/features/settings/view_models/theme_view_model.dart';
import '../ui/features/workspace/views/workspace_page.dart';

void runZephyr(
  PureWriterDatabase database, {
  Object? startupError,
  WorkspaceLayoutRepository? layoutRepository,
}) {
  final layout =
      layoutRepository ??
      FileWorkspaceLayoutRepository(WorkspaceLayoutFileStorage());
  final fonts = FontLibrary(FileSystemFontRepository());
  final backgrounds = BackgroundImageLibrary(
    FileSystemBackgroundImageRepository(),
  );
  final library = LibraryViewModel(
    PureWriterWritingLibraryRepository(database),
    initialError: startupError,
    layoutRepository: layout,
  );
  final backup = BackupViewModel(
    library: library,
    preferencesRepository: FileBackupPreferencesRepository(
      BackupPreferencesFileStorage(),
    ),
  )..load();
  final theme = ThemeViewModel(
    FileThemePreferencesRepository(ThemeFileStorage()),
    fontLibrary: fonts,
    backgroundImages: backgrounds,
  )..load();
  final editorPreferences = EditorPreferencesViewModel(
    FileEditorPreferencesRepository(EditorPreferencesFileStorage()),
    fonts,
  )..load();
  final quickToolbar = QuickToolbarViewModel(
    FileQuickToolbarPreferencesRepository(QuickToolbarFileStorage()),
  )..load();
  final toolbarLibrarySync = QuickToolbarLibrarySync(
    toolbar: quickToolbar,
    libraryRepository: library.repository,
  );
  toolbarLibrarySync.install();
  library.onLibraryLoaded = toolbarLibrarySync.pullOrSeed;
  final keyboardShortcuts = KeyboardShortcutsViewModel(
    FileKeyboardShortcutsRepository(KeyboardShortcutsFileStorage()),
  )..load();
  final llmSettings = LlmSettingsViewModel(
    repository: FileLlmSettingsRepository(),
  )..load();
  final cloudSync = CloudSyncViewModel(
    library: library,
    reloadLocalSettings: () async {
      await theme.load();
      await editorPreferences.load();
      await quickToolbar.load();
      await keyboardShortcuts.load();
      await backup.load();
      await llmSettings.load();
    },
  )..load();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  if (WindowChrome.isDesktop) {
    WindowFrameTracker.active?.beforeClose = () async {
      await windowManager.hide();
      try {
        // Existing manual operations must finish before the database lock is
        // released for the exit backup.
        while (backup.busy || cloudSync.busy) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        await library.flushPending();
        final root = database.location?.rootPath;
        if (root == null || library.needsLibrarySetup || library.isReadOnly) {
          return true;
        }
        final cloudReady = cloudSync.cloudBackupEnabled && cloudSync.isSignedIn;
        final needsWorker = backup.autoBackupEnabled || cloudReady;
        if (!needsWorker) {
          return true;
        }
        await database.close();
        try {
          final result = await HeadlessExitBackup.run(expectedRoot: root);
          if (cloudReady && !result.didCloud) {
            throw StateError('Cloud backup did not complete.');
          }
          await database.openLibrary(root, createIfMissing: false);
        } on Object {
          if (database.location == null) {
            await database.openLibrary(root, createIfMissing: false);
          }
          rethrow;
        }
        return true;
      } on Object catch (error) {
        await windowManager.show();
        await windowManager.focus();
        final messengerContext = messengerKey.currentContext;
        if (messengerContext != null && messengerContext.mounted) {
          messengerKey.currentState?.showSnackBar(
            ZephyrSnackBar.build(
              messengerContext,
              messengerContext.l10n.backupFailed(error.toString()),
            ),
          );
        }
        try {
          await DesktopBackupNotification().show(success: false, error: error);
        } on Object {
          // The visible editor remains open for a retry.
        }
        return false;
      }
    };
  }
  runApp(
    ZephyrApp(
      messengerKey: messengerKey,
      library: library,
      theme: theme,
      editorPreferences: editorPreferences,
      quickToolbar: quickToolbar,
      keyboardShortcuts: keyboardShortcuts,
      settings: SettingsViewModel(
        FileSettingsNavigationRepository(SettingsNavigationFileStorage()),
      )..load(),
      backup: backup,
      cloudSync: cloudSync,
      llmSettings: llmSettings,
    ),
  );
}

class ZephyrApp extends StatelessWidget {
  const ZephyrApp({
    super.key,
    required this.messengerKey,
    required this.library,
    required this.theme,
    required this.editorPreferences,
    required this.quickToolbar,
    required this.keyboardShortcuts,
    required this.settings,
    required this.backup,
    required this.cloudSync,
    required this.llmSettings,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final LibraryViewModel library;
  final ThemeViewModel theme;
  final EditorPreferencesViewModel editorPreferences;
  final QuickToolbarViewModel quickToolbar;
  final KeyboardShortcutsViewModel keyboardShortcuts;
  final SettingsViewModel settings;
  final BackupViewModel backup;
  final CloudSyncViewModel cloudSync;
  final LlmSettingsViewModel llmSettings;

  @override
  Widget build(BuildContext context) => ZephyrScope(
    library: library,
    theme: theme,
    editorPreferences: editorPreferences,
    quickToolbar: quickToolbar,
    keyboardShortcuts: keyboardShortcuts,
    settings: settings,
    backup: backup,
    cloudSync: cloudSync,
    llmSettings: llmSettings,
    child: ListenableBuilder(
      listenable: theme,
      builder: (context, _) => MaterialApp(
        scaffoldMessengerKey: messengerKey,
        title: kReleaseMode
            ? 'Zephyr'
            : kProfileMode
            ? 'Zephyr Profile'
            : 'Zephyr Debug',
        debugShowCheckedModeBanner: false,
        theme: zephyrTheme(theme.tokens, ui: theme.ui),
        locale: _localeFor(theme.ui.localePreference),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          theme.syncPlatformBrightness(
            MediaQuery.platformBrightnessOf(context),
          );
          return child ?? const SizedBox.shrink();
        },
        home: DesktopWindowBackdrop(
          color: Color(theme.tokens.editorSurface),
          child: const WorkspacePage(),
        ),
      ),
    ),
  );
}

Locale? _localeFor(AppLocalePreference preference) => switch (preference) {
  AppLocalePreference.system => null,
  AppLocalePreference.chinese => const Locale('zh'),
  AppLocalePreference.english => const Locale('en'),
};

Future<void> initializeDesktopWindow({
  WindowFrameRepository? frameRepository,
}) async {
  if (!WindowChrome.isDesktop) {
    return;
  }
  await windowManager.ensureInitialized();
  final repository =
      frameRepository ?? FileWindowFrameRepository(WindowFrameFileStorage());
  var frame = WindowFrame.defaults;
  try {
    frame = WindowFrameTracker.clamp(await repository.load());
  } on Object {
    // First launch or a corrupt frame file should still open the shell.
  }
  final options = WindowOptions(
    size: Size(frame.width, frame.height),
    minimumSize: ZephyrControls.minWindowSize,
    center: !frame.hasPosition,
    title: 'Zephyr',
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    if (frame.hasPosition) {
      await WindowFrameTracker.apply(frame);
    } else if (frame.maximized) {
      await windowManager.maximize();
    }
    if (Platform.isWindows) {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
    }
    await windowManager.show();
    await windowManager.focus();
    await WindowChrome.syncNativeMetrics();
    await WindowFrameTracker(repository, initial: frame).start();
  });
}
