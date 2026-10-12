import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/keyboard_shortcuts.dart';
import 'package:zephyr/domain/repositories/keyboard_shortcuts_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/keyboard_shortcuts_view_model.dart';

void main() {
  late _MemoryShortcutsRepository repository;
  late KeyboardShortcutsViewModel model;

  setUp(() {
    repository = _MemoryShortcutsRepository();
    model = KeyboardShortcutsViewModel(
      repository,
      platform: TargetPlatform.macOS,
    );
    addTearDown(model.dispose);
  });

  test(
    'loads saved overrides and presents platform-specific chord labels',
    () async {
      repository.value = ShortcutOverrides.empty.withAction(
        ShortcutActionId.copy,
        [chord('keyK', meta: true)],
      );

      await model.load();

      expect(model.isApple, isTrue);
      expect(model.chordsFor(ShortcutActionId.copy), [
        chord('keyK', meta: true),
      ]);
      expect(model.labelFor(ShortcutActionId.copy), contains('K'));
    },
  );

  test('assigning a conflicting chord displaces the previous action', () {
    final copyChord = model.chordsFor(ShortcutActionId.copy).single;

    model.assignChord(ShortcutActionId.cut, copyChord);

    expect(model.chordsFor(ShortcutActionId.cut), [copyChord]);
    expect(model.chordsFor(ShortcutActionId.copy), isEmpty);
    expect(model.lastDisplaced, contains(ShortcutActionId.copy));
  });

  test('clear, reset, and reset all restore the expected binding scope', () {
    final defaultCopy = model.chordsFor(ShortcutActionId.copy);
    model.clearAction(ShortcutActionId.copy);
    expect(model.chordsFor(ShortcutActionId.copy), isEmpty);
    expect(model.labelFor(ShortcutActionId.copy), '—');

    model.resetAction(ShortcutActionId.copy);
    expect(model.chordsFor(ShortcutActionId.copy), defaultCopy);

    model.clearAction(ShortcutActionId.copy);
    model.resetAll();
    expect(model.chordsFor(ShortcutActionId.copy), defaultCopy);
    expect(model.overrides.isEmpty, isTrue);
  });

  testWidgets('rapid shortcut changes persist only the latest overrides', (
    tester,
  ) async {
    model.clearAction(ShortcutActionId.copy);
    await tester.pump(const Duration(milliseconds: 100));
    model.clearAction(ShortcutActionId.cut);
    await tester.pump(const Duration(milliseconds: 251));

    expect(repository.saves, 1);
    expect(
      repository.value.byAction,
      containsPair(ShortcutActionId.copy, null),
    );
    expect(repository.value.byAction, containsPair(ShortcutActionId.cut, null));
  });
}

class _MemoryShortcutsRepository implements KeyboardShortcutsRepository {
  ShortcutOverrides value = ShortcutOverrides.empty;
  int saves = 0;

  @override
  Future<ShortcutOverrides> load() async => value;

  @override
  Future<void> save(ShortcutOverrides overrides) async {
    saves++;
    value = overrides;
  }
}
