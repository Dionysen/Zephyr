import 'package:flutter/material.dart';

import '../data/repositories/purewriter_writing_library_repository.dart';
import '../data/repositories/file_theme_preferences_repository.dart';
import '../data/services/purewriter_database.dart';
import '../data/services/theme_file_storage.dart';
import '../ui/core/zephyr_theme.dart';
import '../ui/features/editor/view_models/library_view_model.dart';
import '../ui/features/editor/views/library_page.dart';
import '../ui/features/settings/view_models/theme_view_model.dart';

void runZephyr(PureWriterDatabase database, {Object? startupError}) => runApp(
  ZephyrApp(
    viewModel: LibraryViewModel(
      PureWriterWritingLibraryRepository(database),
      initialError: startupError,
    ),
    themeViewModel: ThemeViewModel(
      FileThemePreferencesRepository(ThemeFileStorage()),
    )..load(),
  ),
);

class ZephyrApp extends StatelessWidget {
  const ZephyrApp({
    super.key,
    required this.viewModel,
    required this.themeViewModel,
  });
  final LibraryViewModel viewModel;
  final ThemeViewModel themeViewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: themeViewModel,
    builder: (context, _) => MaterialApp(
      title: 'Zephyr',
      debugShowCheckedModeBanner: false,
      theme: zephyrTheme(themeViewModel.tokens),
      home: LibraryPage(viewModel: viewModel, themeViewModel: themeViewModel),
    ),
  );
}
