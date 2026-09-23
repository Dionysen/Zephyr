import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/repositories/theme_preferences_repository.dart';

class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel(this._repository);

  final ThemePreferencesRepository _repository;
  ThemeTokens _tokens = ThemeTokens.defaults;
  Timer? _pendingSave;

  ThemeTokens get tokens => _tokens;

  Future<void> load() async {
    try {
      _tokens = await _repository.load();
      notifyListeners();
    } on Object {
      // Appearance must never prevent opening a user's writing library.
    }
  }

  void update(ThemeToken token, int value) {
    _tokens = _tokens.withValue(token, value);
    _scheduleSave();
    notifyListeners();
  }

  void applyPreset(ThemePreset preset) {
    _tokens = ThemeTokens.presets[preset]!;
    _scheduleSave();
    notifyListeners();
  }

  void restoreDefaults() {
    _tokens = ThemeTokens.defaults;
    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_repository.save(_tokens));
    });
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
