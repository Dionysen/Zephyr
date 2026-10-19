import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/keyboard_shortcuts.dart';
import 'package:zephyr/domain/use_cases/shortcut_resolver.dart';

void main() {
  test('shortcut lookup reflects updated bindings after a previous lookup', () {
    final resolver = ShortcutResolver(platform: TargetPlatform.windows);
    final defaultCopy = chord('keyC', control: true);
    expect(resolver.actionForChord(defaultCopy), ShortcutActionId.copy);

    final assignment = resolver.assign(
      id: ShortcutActionId.copy,
      chords: [chord('keyK', control: true)],
    );
    resolver.updateOverrides(assignment.overrides);

    expect(resolver.actionForChord(defaultCopy), isNull);
    expect(
      resolver.actionForChord(chord('keyK', control: true)),
      ShortcutActionId.copy,
    );
  });

  test(
    'default bindings can be cleared and restored without a saved override',
    () {
      final resolver = ShortcutResolver(platform: TargetPlatform.macOS);
      final original = resolver.chordsFor(ShortcutActionId.copy);
      resolver.updateOverrides(resolver.clearAction(ShortcutActionId.copy));
      expect(resolver.chordsFor(ShortcutActionId.copy), isEmpty);

      resolver.updateOverrides(resolver.resetAll());
      expect(resolver.overrides.isEmpty, isTrue);
      expect(resolver.chordsFor(ShortcutActionId.copy), original);
    },
  );

  test('logical keys produce stable chord identifiers with modifiers', () {
    expect(
      chordFromLogicalKey(
        LogicalKeyboardKey.keyA,
        control: true,
        meta: false,
        alt: false,
        shift: true,
      ),
      chord('keyA', control: true, shift: true),
    );
    expect(
      chordFromLogicalKey(
        LogicalKeyboardKey.arrowLeft,
        control: false,
        meta: false,
        alt: true,
        shift: false,
      ).keyId,
      'arrowLeft',
    );
  });

  test('shortcut labels use platform modifiers and familiar key names', () {
    expect(formatKeyChord(chord('keyC', meta: true), apple: true), '⌘C');
    expect(
      formatKeyChord(
        chord('arrowLeft', control: true, shift: true),
        apple: false,
      ),
      'Ctrl+Shift+Left',
    );
    expect(formatKeyChord(chord('backspace', alt: true), apple: true), '⌥⌫');
    expect(formatKeyChord(chord('pageDown'), apple: false), 'Page Down');
  });

  test('action identifiers parse only known persisted names', () {
    expect(ShortcutActionIdX.tryParse('copy'), ShortcutActionId.copy);
    expect(ShortcutActionIdX.tryParse('unknown'), isNull);
    expect(ShortcutActionId.closeSettings.group, ShortcutGroup.workspace);
  });
}
