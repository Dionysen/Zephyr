import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_keyboard_shortcuts_repository.dart';
import 'package:zephyr/data/services/keyboard_shortcuts_file_storage.dart';
import 'package:zephyr/domain/models/keyboard_shortcuts.dart';

void main() {
  test('persists shortcut overrides to disk', () async {
    final dir = await Directory.systemTemp.createTemp('zephyr-shortcuts-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final repo = FileKeyboardShortcutsRepository(
      KeyboardShortcutsFileStorage(directoryProvider: () async => dir),
    );

    await repo.save(
      ShortcutOverrides({
        ShortcutActionId.copy: [chord('keyB', control: true)],
      }),
    );
    final loaded = await repo.load();
    expect(loaded.byAction[ShortcutActionId.copy]!.single.keyId, 'keyB');
  });
}
