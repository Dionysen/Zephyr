import 'package:flutter/material.dart';

import '../data/repositories/purewriter_writing_library_repository.dart';
import '../data/services/purewriter_database.dart';
import '../ui/core/zephyr_theme.dart';
import '../ui/features/editor/view_models/library_view_model.dart';
import '../ui/features/editor/views/library_page.dart';

void runZephyr(PureWriterDatabase database, {Object? startupError}) => runApp(
  ZephyrApp(
    viewModel: LibraryViewModel(
      PureWriterWritingLibraryRepository(database),
      initialError: startupError,
    ),
  ),
);

class ZephyrApp extends StatelessWidget {
  const ZephyrApp({super.key, required this.viewModel});
  final LibraryViewModel viewModel;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Zephyr',
    debugShowCheckedModeBanner: false,
    theme: zephyrTheme,
    home: LibraryPage(viewModel: viewModel),
  );
}
