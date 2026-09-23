import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../data/repositories/file_editor_preferences_repository.dart';
import '../data/repositories/file_system_font_repository.dart';
import '../data/repositories/file_theme_preferences_repository.dart';
import '../data/repositories/purewriter_writing_library_repository.dart';
import '../data/services/editor_preferences_file_storage.dart';
import '../data/services/purewriter_database.dart';
import '../data/services/theme_file_storage.dart';
import '../ui/core/zephyr_theme.dart';
import '../ui/features/editor/view_models/library_view_model.dart';
import '../ui/features/editor/view_models/editor_preferences_view_model.dart';
import '../ui/features/editor/views/library_page.dart';
import '../ui/features/settings/view_models/theme_view_model.dart';
import '../ui/features/settings/views/theme_settings_dialog.dart';

void runZephyr(PureWriterDatabase database, {Object? startupError}) {
  final themeViewModel = ThemeViewModel(
    FileThemePreferencesRepository(ThemeFileStorage()),
  )..load();
  final editorPreferencesViewModel = EditorPreferencesViewModel(
    FileEditorPreferencesRepository(EditorPreferencesFileStorage()),
    FileSystemFontRepository(),
  )..load();
  DesktopMultiWindow.setMethodHandler((call, _) async {
    if (call.method == 'reloadPreferences') {
      await Future.wait([
        themeViewModel.load(),
        editorPreferencesViewModel.load(),
      ]);
    }
  });
  runApp(
    ZephyrApp(
      viewModel: LibraryViewModel(
        PureWriterWritingLibraryRepository(database),
        initialError: startupError,
      ),
      themeViewModel: themeViewModel,
      editorPreferencesViewModel: editorPreferencesViewModel,
    ),
  );
}

void runSettingsWindow(int windowId) {
  final themeViewModel = ThemeViewModel(
    FileThemePreferencesRepository(ThemeFileStorage()),
    onPersisted: _notifyMainWindow,
  )..load();
  final editorPreferencesViewModel = EditorPreferencesViewModel(
    FileEditorPreferencesRepository(EditorPreferencesFileStorage()),
    FileSystemFontRepository(),
    onPersisted: _notifyMainWindow,
  )..load();
  runApp(
    SettingsWindowApp(
      themeViewModel: themeViewModel,
      editorPreferencesViewModel: editorPreferencesViewModel,
      onClose: () => unawaited(WindowController.fromWindowId(windowId).hide()),
    ),
  );
}

Future<void> _notifyMainWindow() =>
    DesktopMultiWindow.invokeMethod(0, 'reloadPreferences');

class ZephyrApp extends StatelessWidget {
  const ZephyrApp({
    super.key,
    required this.viewModel,
    required this.themeViewModel,
    required this.editorPreferencesViewModel,
  });
  final LibraryViewModel viewModel;
  final ThemeViewModel themeViewModel;
  final EditorPreferencesViewModel editorPreferencesViewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: themeViewModel,
    builder: (context, _) => MaterialApp(
      title: 'Zephyr',
      debugShowCheckedModeBanner: false,
      theme: zephyrTheme(themeViewModel.tokens),
      home: LibraryPage(
        viewModel: viewModel,
        themeViewModel: themeViewModel,
        editorPreferencesViewModel: editorPreferencesViewModel,
      ),
    ),
  );
}

class SettingsWindowApp extends StatelessWidget {
  const SettingsWindowApp({
    super.key,
    required this.themeViewModel,
    required this.editorPreferencesViewModel,
    required this.onClose,
  });

  final ThemeViewModel themeViewModel;
  final EditorPreferencesViewModel editorPreferencesViewModel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: themeViewModel,
    builder: (context, _) => MaterialApp(
      title: 'Zephyr Settings',
      debugShowCheckedModeBanner: false,
      theme: zephyrTheme(themeViewModel.tokens),
      home: SettingsWindowPage(
        viewModel: themeViewModel,
        editorPreferencesViewModel: editorPreferencesViewModel,
        onClose: onClose,
      ),
    ),
  );
}
