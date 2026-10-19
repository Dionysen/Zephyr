import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../../domain/repositories/writing_library_repository.dart';
import '../view_models/quick_toolbar_view_model.dart';

/// Mirrors IME quick-toolbar prefs into [ZephyrMeta] (`.pwb` backups).
class QuickToolbarLibrarySync {
  QuickToolbarLibrarySync({
    required QuickToolbarViewModel toolbar,
    required WritingLibraryRepository libraryRepository,
  }) : // Keep public named arguments while storing private collaborators.
       // ignore: prefer_initializing_formals
       _toolbar = toolbar,
       // ignore: prefer_initializing_formals
       _repository = libraryRepository;

  final QuickToolbarViewModel _toolbar;
  final WritingLibraryRepository _repository;

  void install() {
    _toolbar.persistConfigToLibrary = _writeToLibrary;
  }

  /// After a library opens, apply stored layout or seed meta from the toolbar file.
  Future<void> pullOrSeed() async {
    if (_repository.location == null) return;
    final stored = await _repository.readQuickToolbarConfig();
    if (stored != null) {
      _toolbar.applyLibraryConfig(stored);
      return;
    }
    await _writeToLibrary(_toolbar.config);
  }

  Future<void> _writeToLibrary(QuickToolbarConfig config) async {
    if (_repository.location == null) return;
    try {
      await _repository.writeQuickToolbarConfig(config);
    } on Object {
      // Read-only libraries keep in-memory + app-support file only.
    }
  }
}
