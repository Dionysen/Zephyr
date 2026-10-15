import '../../../../domain/repositories/writing_library_repository.dart';
import '../view_models/quick_toolbar_view_model.dart';

/// Mirrors format-panel checkbox state into [ZephyrMeta] (`.pwb` backups).
class QuickToolbarLibrarySync {
  QuickToolbarLibrarySync({
    required this._toolbar,
    required this._repository,
  });

  final QuickToolbarViewModel _toolbar;
  final WritingLibraryRepository _repository;

  void install() {
    _toolbar.onFormatSelectionIdsChanged = _writeToLibrary;
  }

  /// After a library opens, apply stored ids or seed meta from the toolbar file.
  Future<void> pullOrSeed() async {
    if (_repository.location == null) return;
    final stored = await _repository.readQuickToolbarFormatSelectionIds();
    if (stored != null) {
      _toolbar.applyFormatSelectionIds(stored);
      return;
    }
    await _writeToLibrary(_toolbar.config.formatSelectionIds);
  }

  Future<void> _writeToLibrary(List<String> ids) async {
    if (_repository.location == null) return;
    try {
      await _repository.writeQuickToolbarFormatSelectionIds(ids);
    } on Object {
      // Read-only libraries keep in-memory + app-support file only.
    }
  }
}
