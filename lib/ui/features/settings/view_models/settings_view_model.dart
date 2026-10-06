import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/settings_section.dart';
import '../../../../domain/repositories/settings_navigation_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository);

  final SettingsNavigationRepository _repository;
  var _section = SettingsSection.theme;

  SettingsSection get section => _section;

  Future<void> load() async {
    try {
      _section = await _repository.load();
      notifyListeners();
    } on Object {
      // Navigation memory must never prevent opening settings.
    }
  }

  void select(SettingsSection section) {
    if (section == _section) {
      return;
    }
    _section = section;
    notifyListeners();
    unawaited(_save(section));
  }

  Future<void> _save(SettingsSection section) async {
    try {
      await _repository.save(section);
    } on Object {
      // Keep the in-session selection even if disk write fails.
    }
  }
}
