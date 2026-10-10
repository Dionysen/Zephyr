import 'package:flutter/foundation.dart';

/// Stable action ids persisted in shortcut overrides.
enum ShortcutActionId {
  copy,
  cut,
  paste,
  selectAll,
  undo,
  redo,
  deleteBackward,
  deleteForward,
  deleteWordBackward,
  deleteWordForward,
  indent,
  outdent,
  newline,
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  moveWordLeft,
  moveWordRight,
  moveLineStart,
  moveLineEnd,
  movePageUp,
  movePageDown,
  moveDocumentStart,
  moveDocumentEnd,
  selectLeft,
  selectRight,
  selectUp,
  selectDown,
  selectWordLeft,
  selectWordRight,
  selectLineStart,
  selectLineEnd,
  selectPageUp,
  selectPageDown,
  selectDocumentStart,
  selectDocumentEnd,
  closeSettings,
}

enum ShortcutGroup {
  clipboard,
  history,
  delete,
  indent,
  newline,
  navigate,
  select,
  workspace,
}

extension ShortcutActionIdX on ShortcutActionId {
  String get id => name;

  ShortcutGroup get group => switch (this) {
    ShortcutActionId.copy ||
    ShortcutActionId.cut ||
    ShortcutActionId.paste ||
    ShortcutActionId.selectAll => ShortcutGroup.clipboard,
    ShortcutActionId.undo || ShortcutActionId.redo => ShortcutGroup.history,
    ShortcutActionId.deleteBackward ||
    ShortcutActionId.deleteForward ||
    ShortcutActionId.deleteWordBackward ||
    ShortcutActionId.deleteWordForward => ShortcutGroup.delete,
    ShortcutActionId.indent || ShortcutActionId.outdent => ShortcutGroup.indent,
    ShortcutActionId.newline => ShortcutGroup.newline,
    ShortcutActionId.moveLeft ||
    ShortcutActionId.moveRight ||
    ShortcutActionId.moveUp ||
    ShortcutActionId.moveDown ||
    ShortcutActionId.moveWordLeft ||
    ShortcutActionId.moveWordRight ||
    ShortcutActionId.moveLineStart ||
    ShortcutActionId.moveLineEnd ||
    ShortcutActionId.movePageUp ||
    ShortcutActionId.movePageDown ||
    ShortcutActionId.moveDocumentStart ||
    ShortcutActionId.moveDocumentEnd => ShortcutGroup.navigate,
    ShortcutActionId.selectLeft ||
    ShortcutActionId.selectRight ||
    ShortcutActionId.selectUp ||
    ShortcutActionId.selectDown ||
    ShortcutActionId.selectWordLeft ||
    ShortcutActionId.selectWordRight ||
    ShortcutActionId.selectLineStart ||
    ShortcutActionId.selectLineEnd ||
    ShortcutActionId.selectPageUp ||
    ShortcutActionId.selectPageDown ||
    ShortcutActionId.selectDocumentStart ||
    ShortcutActionId.selectDocumentEnd => ShortcutGroup.select,
    ShortcutActionId.closeSettings => ShortcutGroup.workspace,
  };

  static ShortcutActionId? tryParse(String raw) {
    for (final value in ShortcutActionId.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

/// One key combination. Defaults may use [primary] (Cmd on Apple, Ctrl elsewhere).
@immutable
class KeyChord {
  const KeyChord({
    required this.keyId,
    this.control = false,
    this.meta = false,
    this.alt = false,
    this.shift = false,
    this.primary = false,
  });

  /// Logical key debug name, e.g. `keyA`, `arrowLeft`, `escape`.
  final String keyId;
  final bool control;
  final bool meta;
  final bool alt;
  final bool shift;

  /// Template flag for defaults only; resolved via [resolvePrimary].
  final bool primary;

  KeyChord resolvePrimary({required bool apple}) {
    if (!primary) return this;
    return KeyChord(
      keyId: keyId,
      control: apple ? control : true,
      meta: apple ? true : meta,
      alt: alt,
      shift: shift,
    );
  }

  bool matches(KeyChord other) =>
      keyId == other.keyId &&
      control == other.control &&
      meta == other.meta &&
      alt == other.alt &&
      shift == other.shift;

  Map<String, Object?> toJson() => {
    'keyId': keyId,
    if (control) 'control': true,
    if (meta) 'meta': true,
    if (alt) 'alt': true,
    if (shift) 'shift': true,
  };

  factory KeyChord.fromJson(Map<String, Object?> json) => KeyChord(
    keyId: json['keyId'] as String? ?? '',
    control: json['control'] == true,
    meta: json['meta'] == true,
    alt: json['alt'] == true,
    shift: json['shift'] == true,
  );

  @override
  bool operator ==(Object other) =>
      other is KeyChord &&
      keyId == other.keyId &&
      control == other.control &&
      meta == other.meta &&
      alt == other.alt &&
      shift == other.shift &&
      primary == other.primary;

  @override
  int get hashCode => Object.hash(keyId, control, meta, alt, shift, primary);
}

KeyChord chord(
  String keyId, {
  bool control = false,
  bool meta = false,
  bool alt = false,
  bool shift = false,
  bool primary = false,
}) => KeyChord(
  keyId: keyId,
  control: control,
  meta: meta,
  alt: alt,
  shift: shift,
  primary: primary,
);

/// Platform-resolved bindings for every action.
@immutable
class ShortcutBindings {
  const ShortcutBindings(this.byAction);

  final Map<ShortcutActionId, List<KeyChord>> byAction;

  List<KeyChord> chordsFor(ShortcutActionId id) =>
      byAction[id] ?? const <KeyChord>[];

  /// Chord → action for dispatch.
  Map<KeyChord, ShortcutActionId> invert() {
    final out = <KeyChord, ShortcutActionId>{};
    for (final entry in byAction.entries) {
      for (final c in entry.value) {
        out[c] = entry.key;
      }
    }
    return out;
  }

  ShortcutBindings copyWithAction(
    ShortcutActionId id,
    List<KeyChord> chords,
  ) {
    final next = Map<ShortcutActionId, List<KeyChord>>.from(byAction);
    if (chords.isEmpty) {
      next.remove(id);
    } else {
      next[id] = List<KeyChord>.from(chords);
    }
    return ShortcutBindings(next);
  }
}

bool isApplePlatform(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

/// Industry-default bindings. [primary] is resolved for the platform.
ShortcutBindings defaultShortcutBindings(TargetPlatform platform) {
  final apple = isApplePlatform(platform);
  KeyChord p(String key, {bool shift = false, bool alt = false}) =>
      chord(key, primary: true, shift: shift, alt: alt).resolvePrimary(
        apple: apple,
      );
  KeyChord c(String key, {bool shift = false, bool alt = false, bool control = false, bool meta = false}) =>
      chord(key, shift: shift, alt: alt, control: control, meta: meta);

  final map = <ShortcutActionId, List<KeyChord>>{
    ShortcutActionId.copy: [p('keyC')],
    ShortcutActionId.cut: [p('keyX')],
    ShortcutActionId.paste: [p('keyV')],
    ShortcutActionId.selectAll: [p('keyA')],
    ShortcutActionId.undo: [p('keyZ')],
    ShortcutActionId.redo: apple
        ? [p('keyZ', shift: true)]
        : [p('keyZ', shift: true), p('keyY')],
    ShortcutActionId.deleteBackward: [c('backspace')],
    ShortcutActionId.deleteForward: [c('delete')],
    ShortcutActionId.deleteWordBackward: apple
        ? [c('backspace', alt: true)]
        : [c('backspace', control: true)],
    ShortcutActionId.deleteWordForward: apple
        ? [c('delete', alt: true)]
        : [c('delete', control: true)],
    ShortcutActionId.indent: [c('tab')],
    ShortcutActionId.outdent: [c('tab', shift: true)],
    ShortcutActionId.newline: [c('enter'), c('numpadEnter')],
    ShortcutActionId.moveLeft: [c('arrowLeft')],
    ShortcutActionId.moveRight: [c('arrowRight')],
    ShortcutActionId.moveUp: [c('arrowUp')],
    ShortcutActionId.moveDown: [c('arrowDown')],
    ShortcutActionId.moveWordLeft: apple
        ? [c('arrowLeft', alt: true)]
        : [c('arrowLeft', control: true)],
    ShortcutActionId.moveWordRight: apple
        ? [c('arrowRight', alt: true)]
        : [c('arrowRight', control: true)],
    ShortcutActionId.moveLineStart: apple
        ? [c('home'), p('arrowLeft')]
        : [c('home')],
    ShortcutActionId.moveLineEnd: apple
        ? [c('end'), p('arrowRight')]
        : [c('end')],
    ShortcutActionId.movePageUp: [c('pageUp')],
    ShortcutActionId.movePageDown: [c('pageDown')],
    ShortcutActionId.moveDocumentStart: apple
        ? [p('arrowUp')]
        : [c('home', control: true)],
    ShortcutActionId.moveDocumentEnd: apple
        ? [p('arrowDown')]
        : [c('end', control: true)],
    ShortcutActionId.selectLeft: [c('arrowLeft', shift: true)],
    ShortcutActionId.selectRight: [c('arrowRight', shift: true)],
    ShortcutActionId.selectUp: [c('arrowUp', shift: true)],
    ShortcutActionId.selectDown: [c('arrowDown', shift: true)],
    ShortcutActionId.selectWordLeft: apple
        ? [c('arrowLeft', alt: true, shift: true)]
        : [c('arrowLeft', control: true, shift: true)],
    ShortcutActionId.selectWordRight: apple
        ? [c('arrowRight', alt: true, shift: true)]
        : [c('arrowRight', control: true, shift: true)],
    ShortcutActionId.selectLineStart: apple
        ? [c('home', shift: true), p('arrowLeft', shift: true)]
        : [c('home', shift: true)],
    ShortcutActionId.selectLineEnd: apple
        ? [c('end', shift: true), p('arrowRight', shift: true)]
        : [c('end', shift: true)],
    ShortcutActionId.selectPageUp: [c('pageUp', shift: true)],
    ShortcutActionId.selectPageDown: [c('pageDown', shift: true)],
    ShortcutActionId.selectDocumentStart: apple
        ? [p('arrowUp', shift: true)]
        : [c('home', control: true, shift: true)],
    ShortcutActionId.selectDocumentEnd: apple
        ? [p('arrowDown', shift: true)]
        : [c('end', control: true, shift: true)],
    ShortcutActionId.closeSettings: [c('escape')],
  };

  return ShortcutBindings(map);
}

/// User overrides: only actions that differ from the platform default.
@immutable
class ShortcutOverrides {
  const ShortcutOverrides(this.byAction);

  static const empty = ShortcutOverrides({});

  /// Null list means "cleared / unbound"; non-null replaces defaults for that action.
  final Map<ShortcutActionId, List<KeyChord>?> byAction;

  bool get isEmpty => byAction.isEmpty;

  Map<String, Object?> toJson() => {
    for (final e in byAction.entries)
      e.key.id: e.value?.map((c) => c.toJson()).toList(),
  };

  factory ShortcutOverrides.fromJson(Map<String, Object?> json) {
    final out = <ShortcutActionId, List<KeyChord>?>{};
    for (final entry in json.entries) {
      final id = ShortcutActionIdX.tryParse(entry.key);
      if (id == null) continue;
      final value = entry.value;
      if (value == null) {
        out[id] = null;
        continue;
      }
      if (value is! List) continue;
      out[id] = [
        for (final item in value)
          if (item is Map)
            KeyChord.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
      ];
    }
    return ShortcutOverrides(out);
  }

  ShortcutOverrides withAction(ShortcutActionId id, List<KeyChord>? chords) {
    final next = Map<ShortcutActionId, List<KeyChord>?>.from(byAction);
    next[id] = chords == null ? null : List<KeyChord>.from(chords);
    return ShortcutOverrides(next);
  }

  ShortcutOverrides withoutAction(ShortcutActionId id) {
    final next = Map<ShortcutActionId, List<KeyChord>?>.from(byAction);
    next.remove(id);
    return ShortcutOverrides(next);
  }
}
