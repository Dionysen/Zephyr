import 'package:flutter/material.dart';

import '../features/editor/view_models/editor_preferences_view_model.dart';
import '../features/editor/view_models/library_view_model.dart';
import '../features/editor/view_models/quick_toolbar_view_model.dart';
import '../features/settings/view_models/backup_view_model.dart';
import '../features/settings/view_models/keyboard_shortcuts_view_model.dart';
import '../features/settings/view_models/settings_view_model.dart';
import '../features/settings/view_models/theme_view_model.dart';

/// Application-scoped view models. Feature widgets read this instead of
/// threading constructors through every layout.
class ZephyrScope extends InheritedWidget {
  const ZephyrScope({
    super.key,
    required this.library,
    required this.theme,
    required this.editorPreferences,
    required this.quickToolbar,
    required this.keyboardShortcuts,
    required this.settings,
    required this.backup,
    required super.child,
  });

  final LibraryViewModel library;
  final ThemeViewModel theme;
  final EditorPreferencesViewModel editorPreferences;
  final QuickToolbarViewModel quickToolbar;
  final KeyboardShortcutsViewModel keyboardShortcuts;
  final SettingsViewModel settings;
  final BackupViewModel backup;

  static ZephyrScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZephyrScope>();
    assert(scope != null, 'ZephyrScope is missing from the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ZephyrScope oldWidget) =>
      library != oldWidget.library ||
      theme != oldWidget.theme ||
      editorPreferences != oldWidget.editorPreferences ||
      quickToolbar != oldWidget.quickToolbar ||
      keyboardShortcuts != oldWidget.keyboardShortcuts ||
      settings != oldWidget.settings ||
      backup != oldWidget.backup;
}
