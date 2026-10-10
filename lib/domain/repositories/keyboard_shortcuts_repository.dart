import '../models/keyboard_shortcuts.dart';

abstract interface class KeyboardShortcutsRepository {
  Future<ShortcutOverrides> load();
  Future<void> save(ShortcutOverrides overrides);
}
