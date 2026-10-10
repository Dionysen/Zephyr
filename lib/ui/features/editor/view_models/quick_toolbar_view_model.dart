import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../../domain/repositories/quick_toolbar_preferences_repository.dart';

class QuickToolbarViewModel extends ChangeNotifier {
  QuickToolbarViewModel(this._repository);

  final QuickToolbarPreferencesRepository _repository;
  static const _uuid = Uuid();

  /// Used only when tools open before any soft-keyboard height was observed.
  static const panelFallbackHeight = 280.0;

  QuickToolbarConfig _config = QuickToolbarConfig.defaults;
  Timer? _pendingSave;
  var _toolsDrawerOpen = false;
  /// Keep the latched panel slot until the soft keyboard fills it again.
  var _holdingPanelForIme = false;
  double _latchedKeyboardHeight = 0;
  double _lastKeyboardInset = 0;

  QuickToolbarConfig get config => _config;
  bool get toolsDrawerOpen => _toolsDrawerOpen;
  bool get holdingPanelForIme => _holdingPanelForIme;
  double get latchedKeyboardHeight => _latchedKeyboardHeight;

  /// Panel chrome is active (tools drawer, or empty hold while IME rises).
  bool get usesFixedPanel => _toolsDrawerOpen || _holdingPanelForIme;

  Future<void> load() async {
    try {
      _config = (await _repository.load()).normalized();
      notifyListeners();
    } on Object {
      // Keep defaults if storage is unavailable.
    }
  }

  /// Tracks live IME inset. Rising inset while the tools drawer is open means
  /// the user focused the body again — dismiss the drawer (keep the panel slot).
  void reportKeyboardInset(double height) {
    final prev = _lastKeyboardInset;
    _lastKeyboardInset = height;
    if (_toolsDrawerOpen && height > prev + 8 && height > 40) {
      restoreImeFromTools();
      return;
    }
    rememberKeyboardHeight(height);
  }

  void rememberKeyboardHeight(double height) {
    // Freeze while the tools panel is open so the bar does not drift as the
    // soft keyboard animates away.
    if (_toolsDrawerOpen) return;
    if (_holdingPanelForIme) {
      // Release only when the IME has essentially filled the latched slot.
      // Early release (e.g. at 92%) drops effective bottom cover and bounces.
      final target = toolsPanelHeight;
      if (height + 0.5 >= target) {
        _holdingPanelForIme = false;
        _latchedKeyboardHeight = height;
        notifyListeners();
      }
      return;
    }
    if (height < 80) return;
    if ((height - _latchedKeyboardHeight).abs() < 0.5) return;
    _latchedKeyboardHeight = height;
    notifyListeners();
  }

  /// Opens the tools panel, freezing [panelHeight] for the session.
  void openToolsDrawer({required double keyboardHeight}) {
    if (_toolsDrawerOpen) return;
    _holdingPanelForIme = false;
    if (keyboardHeight >= 80) {
      _latchedKeyboardHeight = keyboardHeight;
      _lastKeyboardInset = keyboardHeight;
    }
    _toolsDrawerOpen = true;
    notifyListeners();
  }

  /// Closes the tools drawer but keeps the panel slot until the IME rises.
  void restoreImeFromTools() {
    if (!_toolsDrawerOpen && !_holdingPanelForIme) return;
    _toolsDrawerOpen = false;
    _holdingPanelForIme = true;
    notifyListeners();
  }

  void setToolsDrawerOpen(bool open) {
    if (_toolsDrawerOpen == open) return;
    _toolsDrawerOpen = open;
    if (open) _holdingPanelForIme = false;
    notifyListeners();
  }

  /// Fixed panel height under the toolbar while tools are open.
  double get toolsPanelHeight => _latchedKeyboardHeight > 0
      ? _latchedKeyboardHeight
      : panelFallbackHeight;

  void toggleToolsDrawer() => setToolsDrawerOpen(!_toolsDrawerOpen);

  void closeToolsDrawer() {
    _holdingPanelForIme = false;
    setToolsDrawerOpen(false);
  }

  /// [newIndex] is the destination after removal (as from [onReorderItem]).
  void reorderPinned(int oldIndex, int newIndex) {
    final list = List<String>.from(_config.pinnedIds);
    final id = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), id);
    _update(_config.copyWith(pinnedIds: list));
  }

  /// [newIndex] is the destination after removal (as from [onReorderItem]).
  void reorderCustom(int oldIndex, int newIndex) {
    final list = List<String>.from(_config.customIds);
    final id = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), id);
    _update(_config.copyWith(customIds: list));
  }

  void moveToPinned(String id, {int? index}) {
    if (id == QuickTool.toolsId) return;
    final alreadyPinned = _config.pinnedIds.contains(id);
    if (!alreadyPinned &&
        _config.pinnedIds.length >= QuickToolbarConfig.maxPinned) {
      return;
    }
    final custom = List<String>.from(_config.customIds)..remove(id);
    final pinned = List<String>.from(_config.pinnedIds)..remove(id);
    final at = (index ?? pinned.length).clamp(0, pinned.length);
    pinned.insert(at, id);
    _update(_config.copyWith(pinnedIds: pinned, customIds: custom));
  }

  void moveToCustom(String id, {int? index}) {
    if (id == QuickTool.toolsId) return;
    final pinned = List<String>.from(_config.pinnedIds)..remove(id);
    final custom = List<String>.from(_config.customIds)..remove(id);
    final at = (index ?? custom.length).clamp(0, custom.length);
    custom.insert(at, id);
    _update(_config.copyWith(pinnedIds: pinned, customIds: custom));
  }

  void removeTool(String id) {
    if (id == QuickTool.toolsId) return;
    final pinned = List<String>.from(_config.pinnedIds)..remove(id);
    final custom = List<String>.from(_config.customIds)..remove(id);
    var catalog = _config.catalog;
    final tool = _config.toolById(id);
    if (tool?.kind == QuickToolKind.phrase) {
      catalog = catalog.where((t) => t.id != id).toList();
    }
    _update(
      _config.copyWith(pinnedIds: pinned, customIds: custom, catalog: catalog),
    );
  }

  void addBuiltin(QuickTool tool, {bool toPinned = false}) {
    if (tool.kind == QuickToolKind.tools || tool.kind == QuickToolKind.phrase) {
      return;
    }
    if (_config.placedIds.contains(tool.id)) return;
    if (toPinned) {
      moveToPinned(tool.id);
    } else {
      moveToCustom(tool.id);
    }
  }

  void addPhrase({
    required String label,
    required String payload,
    bool toPinned = false,
  }) {
    final trimmedLabel = label.trim();
    final text = payload;
    if (trimmedLabel.isEmpty || text.isEmpty) return;
    final tool = QuickTool(
      id: _uuid.v4(),
      kind: QuickToolKind.phrase,
      label: trimmedLabel,
      payload: text,
    );
    final catalog = [..._config.catalog, tool];
    if (toPinned && _config.pinnedIds.length < QuickToolbarConfig.maxPinned) {
      _update(
        _config.copyWith(
          catalog: catalog,
          pinnedIds: [..._config.pinnedIds, tool.id],
        ),
      );
    } else {
      _update(
        _config.copyWith(
          catalog: catalog,
          customIds: [..._config.customIds, tool.id],
        ),
      );
    }
  }

  void updatePhrase(String id, {required String label, required String payload}) {
    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty || payload.isEmpty) return;
    final catalog = _config.catalog.map((t) {
      if (t.id != id || t.kind != QuickToolKind.phrase) return t;
      return t.copyWith(label: trimmedLabel, payload: payload);
    }).toList();
    _update(_config.copyWith(catalog: catalog));
  }

  void _update(QuickToolbarConfig value) {
    _config = value.normalized();
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_save(_config));
    });
    notifyListeners();
  }

  Future<void> _save(QuickToolbarConfig value) async {
    try {
      await _repository.save(value);
    } on Object {
      // In-memory layout remains usable.
    }
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
