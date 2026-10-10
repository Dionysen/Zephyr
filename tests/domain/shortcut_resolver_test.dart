import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/keyboard_shortcuts.dart';
import 'package:zephyr/domain/use_cases/shortcut_resolver.dart';

void main() {
  test('PC defaults use control as primary for copy', () {
    final bindings = defaultShortcutBindings(TargetPlatform.windows);
    final copy = bindings.chordsFor(ShortcutActionId.copy).single;
    expect(copy.control, isTrue);
    expect(copy.meta, isFalse);
    expect(copy.keyId, 'keyC');
  });

  test('Apple defaults use meta as primary for copy', () {
    final bindings = defaultShortcutBindings(TargetPlatform.macOS);
    final copy = bindings.chordsFor(ShortcutActionId.copy).single;
    expect(copy.meta, isTrue);
    expect(copy.control, isFalse);
  });

  test('PC word left is control+arrow; Apple is alt+arrow', () {
    final pc = defaultShortcutBindings(TargetPlatform.linux)
        .chordsFor(ShortcutActionId.moveWordLeft)
        .single;
    expect(pc.control, isTrue);
    expect(pc.alt, isFalse);

    final apple = defaultShortcutBindings(TargetPlatform.iOS)
        .chordsFor(ShortcutActionId.moveWordLeft)
        .single;
    expect(apple.alt, isTrue);
    expect(apple.control, isFalse);
  });

  test('overrides replace defaults and clear stores unbound', () {
    final resolver = ShortcutResolver(platform: TargetPlatform.windows);
    final assigned = resolver.assign(
      id: ShortcutActionId.copy,
      chords: [chord('keyB', control: true)],
    );
    resolver.updateOverrides(assigned.overrides);
    expect(
      resolver.chordsFor(ShortcutActionId.copy).single.keyId,
      'keyB',
    );

    resolver.updateOverrides(resolver.clearAction(ShortcutActionId.copy));
    expect(resolver.chordsFor(ShortcutActionId.copy), isEmpty);

    resolver.updateOverrides(resolver.resetAction(ShortcutActionId.copy));
    expect(
      resolver.chordsFor(ShortcutActionId.copy).single.keyId,
      'keyC',
    );
  });

  test('assign steals conflicting chords from other actions', () {
    final resolver = ShortcutResolver(platform: TargetPlatform.windows);
    final result = resolver.assign(
      id: ShortcutActionId.paste,
      chords: [chord('keyC', control: true)],
    );
    expect(result.displaced, contains(ShortcutActionId.copy));
    resolver.updateOverrides(result.overrides);
    expect(resolver.chordsFor(ShortcutActionId.copy), isEmpty);
    expect(
      resolver.actionForChord(chord('keyC', control: true)),
      ShortcutActionId.paste,
    );
  });

  test('overrides json round-trips', () {
    final original = ShortcutOverrides({
      ShortcutActionId.undo: [chord('keyU', control: true)],
      ShortcutActionId.redo: null,
    });
    final restored = ShortcutOverrides.fromJson(original.toJson());
    expect(restored.byAction[ShortcutActionId.undo]!.single.keyId, 'keyU');
    expect(restored.byAction[ShortcutActionId.redo], isNull);
  });
}
