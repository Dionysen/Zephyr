import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../data/repositories/file_editor_preferences_repository.dart';
import '../data/repositories/file_settings_navigation_repository.dart';
import '../data/repositories/file_system_font_repository.dart';
import '../data/repositories/file_theme_preferences_repository.dart';
import '../data/repositories/file_window_frame_repository.dart';
import '../data/repositories/file_workspace_layout_repository.dart';
import '../data/repositories/purewriter_writing_library_repository.dart';
import '../data/services/editor_preferences_file_storage.dart';
import '../data/services/purewriter_database.dart';
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
import '../ui/core/zephyr_scope.dart';
import '../ui/core/zephyr_theme.dart';
import '../ui/features/editor/view_models/editor_preferences_view_model.dart';
import '../ui/features/editor/view_models/library_view_model.dart';
import '../ui/features/settings/view_models/font_library.dart';
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
  runApp(
    ZephyrApp(
      library: LibraryViewModel(
        PureWriterWritingLibraryRepository(database),
        initialError: startupError,
        layoutRepository: layout,
      ),
      theme: ThemeViewModel(
        FileThemePreferencesRepository(ThemeFileStorage()),
        fontLibrary: fonts,
      )..load(),
      editorPreferences: EditorPreferencesViewModel(
        FileEditorPreferencesRepository(EditorPreferencesFileStorage()),
        fonts,
      )..load(),
      settings: SettingsViewModel(
        FileSettingsNavigationRepository(SettingsNavigationFileStorage()),
      )..load(),
    ),
  );
}

class ZephyrApp extends StatelessWidget {
  const ZephyrApp({
    super.key,
    required this.library,
    required this.theme,
    required this.editorPreferences,
    required this.settings,
  });

  final LibraryViewModel library;
  final ThemeViewModel theme;
  final EditorPreferencesViewModel editorPreferences;
  final SettingsViewModel settings;

  @override
  Widget build(BuildContext context) => ZephyrScope(
    library: library,
    theme: theme,
    editorPreferences: editorPreferences,
    settings: settings,
    child: ListenableBuilder(
      listenable: theme,
      builder: (context, _) => MaterialApp(
        title: 'Zephyr',
        debugShowCheckedModeBanner: false,
        theme: zephyrTheme(theme.tokens, ui: theme.ui),
        locale: _localeFor(theme.ui.localePreference),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      frameRepository ??
      FileWindowFrameRepository(WindowFrameFileStorage());
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
