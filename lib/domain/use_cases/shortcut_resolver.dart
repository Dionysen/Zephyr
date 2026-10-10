import 'package:flutter/services.dart';

import '../models/keyboard_shortcuts.dart';

/// Merges platform defaults with user overrides and answers chord lookups.
class ShortcutResolver {
  ShortcutResolver({
    required this.platform,
    ShortcutOverrides overrides = ShortcutOverrides.empty,
  }) : _overrides = overrides,
       _effective = mergeBindings(
         defaults: defaultShortcutBindings(platform),
         overrides: overrides,
       );

  final TargetPlatform platform;
  ShortcutOverrides _overrides;
  ShortcutBindings _effective;
  Map<KeyChord, ShortcutActionId>? _index;

  ShortcutOverrides get overrides => _overrides;
  ShortcutBindings get effective => _effective;

  void updateOverrides(ShortcutOverrides overrides) {
    _overrides = overrides;
    _effective = mergeBindings(
      defaults: defaultShortcutBindings(platform),
      overrides: overrides,
    );
    _index = null;
  }

  List<KeyChord> chordsFor(ShortcutActionId id) => _effective.chordsFor(id);

  ShortcutActionId? actionForChord(KeyChord chord) {
    _index ??= _effective.invert();
    return _index![chord];
  }

  ShortcutActionId? actionForKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return null;
    return actionForChord(chordFromKeyEvent(event));
  }

  /// Assign [chords] to [id], stealing any conflicting chords from other actions.
  /// Returns the previous owners that lost chords (for UI hints).
  ({ShortcutOverrides overrides, List<ShortcutActionId> displaced}) assign({
    required ShortcutActionId id,
    required List<KeyChord> chords,
  }) {
    final defaults = defaultShortcutBindings(platform);
    var nextOverrides = _overrides;
    final displaced = <ShortcutActionId>[];

    // Start from current effective map, then apply assignment with steal.
    final working = Map<ShortcutActionId, List<KeyChord>>.from(
      _effective.byAction,
    );

    for (final chord in chords) {
      for (final entry in working.entries.toList()) {
        if (entry.key == id) continue;
        if (!entry.value.any(chord.matches)) continue;
        displaced.add(entry.key);
        final remaining = [
          for (final c in entry.value)
            if (!c.matches(chord)) c,
        ];
        working[entry.key] = remaining;
        nextOverrides = _overrideRelativeToDefaults(
          nextOverrides,
          defaults,
          entry.key,
          remaining,
        );
      }
    }

    working[id] = List<KeyChord>.from(chords);
    nextOverrides = _overrideRelativeToDefaults(
      nextOverrides,
      defaults,
      id,
      chords,
    );

    return (overrides: nextOverrides, displaced: displaced);
  }

  ShortcutOverrides clearAction(ShortcutActionId id) {
    final defaults = defaultShortcutBindings(platform);
    return _overrideRelativeToDefaults(
      _overrides,
      defaults,
      id,
      const <KeyChord>[],
    );
  }

  ShortcutOverrides resetAction(ShortcutActionId id) =>
      _overrides.withoutAction(id);

  ShortcutOverrides resetAll() => ShortcutOverrides.empty;
}

ShortcutOverrides _overrideRelativeToDefaults(
  ShortcutOverrides current,
  ShortcutBindings defaults,
  ShortcutActionId id,
  List<KeyChord> chords,
) {
  final defaultChords = defaults.chordsFor(id);
  if (_sameChordLists(chords, defaultChords)) {
    return current.withoutAction(id);
  }
  if (chords.isEmpty) {
    return current.withAction(id, null);
  }
  return current.withAction(id, chords);
}

bool _sameChordLists(List<KeyChord> a, List<KeyChord> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!a[i].matches(b[i])) return false;
  }
  return true;
}

ShortcutBindings mergeBindings({
  required ShortcutBindings defaults,
  required ShortcutOverrides overrides,
}) {
  final out = Map<ShortcutActionId, List<KeyChord>>.from(defaults.byAction);
  for (final entry in overrides.byAction.entries) {
    final value = entry.value;
    if (value == null) {
      out.remove(entry.key);
    } else {
      out[entry.key] = List<KeyChord>.from(value);
    }
  }
  return ShortcutBindings(out);
}

KeyChord chordFromKeyEvent(KeyEvent event) {
  final keyboard = HardwareKeyboard.instance;
  return KeyChord(
    keyId: _logicalKeyId(event.logicalKey),
    control: keyboard.isControlPressed,
    meta: keyboard.isMetaPressed,
    alt: keyboard.isAltPressed,
    shift: keyboard.isShiftPressed,
  );
}

/// Build a chord for matching when modifiers are already known from the event.
KeyChord chordFromLogicalKey(
  LogicalKeyboardKey key, {
  required bool control,
  required bool meta,
  required bool alt,
  required bool shift,
}) => KeyChord(
  keyId: _logicalKeyId(key),
  control: control,
  meta: meta,
  alt: alt,
  shift: shift,
);

String _logicalKeyId(LogicalKeyboardKey key) {
  // Prefer stable keyLabel-free debug names used across Flutter versions.
  final label = key.keyLabel;
  if (label.length == 1) {
    final lower = label.toLowerCase();
    if (lower.compareTo('a') >= 0 && lower.compareTo('z') <= 0) {
      return 'key${lower.toUpperCase()}';
    }
    if (lower.compareTo('0') >= 0 && lower.compareTo('9') <= 0) {
      return 'digit$lower';
    }
  }
  // Fall back to known keys via identity with Flutter's predefined keys.
  if (key == LogicalKeyboardKey.backspace) return 'backspace';
  if (key == LogicalKeyboardKey.delete) return 'delete';
  if (key == LogicalKeyboardKey.tab) return 'tab';
  if (key == LogicalKeyboardKey.enter) return 'enter';
  if (key == LogicalKeyboardKey.numpadEnter) return 'numpadEnter';
  if (key == LogicalKeyboardKey.escape) return 'escape';
  if (key == LogicalKeyboardKey.arrowLeft) return 'arrowLeft';
  if (key == LogicalKeyboardKey.arrowRight) return 'arrowRight';
  if (key == LogicalKeyboardKey.arrowUp) return 'arrowUp';
  if (key == LogicalKeyboardKey.arrowDown) return 'arrowDown';
  if (key == LogicalKeyboardKey.home) return 'home';
  if (key == LogicalKeyboardKey.end) return 'end';
  if (key == LogicalKeyboardKey.pageUp) return 'pageUp';
  if (key == LogicalKeyboardKey.pageDown) return 'pageDown';
  if (key == LogicalKeyboardKey.space) return 'space';
  // debugName like "Key A" → keyA-ish; use hash-stable string from keyId.
  final debug = key.debugName;
  if (debug != null && debug.isNotEmpty) {
    return _debugNameToId(debug);
  }
  return 'key_${key.keyId}';
}

String _debugNameToId(String debugName) {
  final compact = debugName
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll('_', '');
  if (compact.isEmpty) return compact;
  return compact[0].toLowerCase() + compact.substring(1);
}

/// Human-readable chord label for settings UI.
String formatKeyChord(KeyChord chord, {required bool apple}) {
  final parts = <String>[];
  if (apple) {
    if (chord.control) parts.add('⌃');
    if (chord.alt) parts.add('⌥');
    if (chord.shift) parts.add('⇧');
    if (chord.meta) parts.add('⌘');
  } else {
    if (chord.control) parts.add('Ctrl');
    if (chord.alt) parts.add('Alt');
    if (chord.shift) parts.add('Shift');
    if (chord.meta) parts.add('Meta');
  }
  parts.add(_keyDisplayName(chord.keyId, apple: apple));
  return apple ? parts.join('') : parts.join('+');
}

String _keyDisplayName(String keyId, {required bool apple}) {
  return switch (keyId) {
    'arrowLeft' => apple ? '←' : 'Left',
    'arrowRight' => apple ? '→' : 'Right',
    'arrowUp' => apple ? '↑' : 'Up',
    'arrowDown' => apple ? '↓' : 'Down',
    'backspace' => apple ? '⌫' : 'Backspace',
    'delete' => apple ? '⌦' : 'Delete',
    'enter' || 'numpadEnter' => apple ? '↩' : 'Enter',
    'tab' => apple ? '⇥' : 'Tab',
    'escape' => 'Esc',
    'home' => 'Home',
    'end' => 'End',
    'pageUp' => 'Page Up',
    'pageDown' => 'Page Down',
    'space' => 'Space',
    _ when keyId.startsWith('key') && keyId.length == 4 =>
      keyId.substring(3).toUpperCase(),
    _ when keyId.startsWith('digit') && keyId.length == 6 => keyId.substring(5),
    _ => keyId,
  };
}
