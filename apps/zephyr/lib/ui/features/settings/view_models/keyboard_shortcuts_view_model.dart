import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../../../domain/repositories/keyboard_shortcuts_repository.dart';
import '../../../../domain/use_cases/shortcut_resolver.dart';

class KeyboardShortcutsViewModel extends ChangeNotifier {
  KeyboardShortcutsViewModel(
    this._repository, {
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform,
       _resolver = ShortcutResolver(
         platform: platform ?? defaultTargetPlatform,
       );

  final KeyboardShortcutsRepository _repository;
  final TargetPlatform _platform;
  ShortcutResolver _resolver;
  Timer? _pendingSave;
  List<ShortcutActionId> _lastDisplaced = const [];

  TargetPlatform get platform => _platform;
  bool get isApple => isApplePlatform(_platform);
  ShortcutResolver get resolver => _resolver;
  ShortcutBindings get bindings => _resolver.effective;
  ShortcutOverrides get overrides => _resolver.overrides;
  List<ShortcutActionId> get lastDisplaced => _lastDisplaced;

  Future<void> load() async {
    try {
      final loaded = await _repository.load();
      _resolver = ShortcutResolver(platform: _platform, overrides: loaded);
      notifyListeners();
    } on Object {
      // Keep defaults if storage is unavailable.
    }
  }

  ShortcutActionId? actionForKeyEvent(KeyEvent event) =>
      _resolver.actionForKeyEvent(event);

  List<KeyChord> chordsFor(ShortcutActionId id) => _resolver.chordsFor(id);

  String labelFor(ShortcutActionId id) {
    final chords = chordsFor(id);
    if (chords.isEmpty) return '—';
    return chords
        .map((c) => formatKeyChord(c, apple: isApple))
        .join(' / ');
  }

  void assignChords(ShortcutActionId id, List<KeyChord> chords) {
    final result = _resolver.assign(id: id, chords: chords);
    _lastDisplaced = result.displaced;
    _resolver.updateOverrides(result.overrides);
    _scheduleSave();
    notifyListeners();
  }

  void assignChord(ShortcutActionId id, KeyChord chord) =>
      assignChords(id, [chord]);

  void clearAction(ShortcutActionId id) {
    _lastDisplaced = const [];
    _resolver.updateOverrides(_resolver.clearAction(id));
    _scheduleSave();
    notifyListeners();
  }

  void resetAction(ShortcutActionId id) {
    _lastDisplaced = const [];
    _resolver.updateOverrides(_resolver.resetAction(id));
    _scheduleSave();
    notifyListeners();
  }

  void resetAll() {
    _lastDisplaced = const [];
    _resolver.updateOverrides(_resolver.resetAll());
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_repository.save(_resolver.overrides));
    });
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
