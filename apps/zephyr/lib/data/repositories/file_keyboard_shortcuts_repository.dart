import '../../domain/models/keyboard_shortcuts.dart';
import '../../domain/repositories/keyboard_shortcuts_repository.dart';
import '../services/keyboard_shortcuts_file_storage.dart';

class FileKeyboardShortcutsRepository implements KeyboardShortcutsRepository {
  FileKeyboardShortcutsRepository(this._storage);
  final KeyboardShortcutsFileStorage _storage;

  @override
  Future<ShortcutOverrides> load() async {
    final values = await _storage.read();
    if (values == null) return ShortcutOverrides.empty;
    return ShortcutOverrides.fromJson(values);
  }

  @override
  Future<void> save(ShortcutOverrides overrides) =>
      _storage.write(overrides.toJson());
}
