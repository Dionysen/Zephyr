import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/settings_navigation.dart';
import '../../../../domain/models/settings_section.dart';
import '../../../../domain/repositories/settings_navigation_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository);

  final SettingsNavigationRepository _repository;
  var _section = SettingsNavigation.defaults.section;
  var _sidebarWidth = SettingsNavigation.defaults.sidebarWidth;
  var _isResizingSidebar = false;
  Timer? _pendingSave;

  SettingsSection get section => _section;
  double get sidebarWidth => _sidebarWidth;
  bool get isResizingSidebar => _isResizingSidebar;

  Future<void> load() async {
    try {
      final navigation = await _repository.load();
      _section = navigation.section;
      _sidebarWidth = navigation.sidebarWidth;
      notifyListeners();
    } on Object {
      // Navigation memory must never prevent opening settings.
    }
  }

  void select(SettingsSection section) {
    if (section == _section) {
      return;
    }
    _pendingSave?.cancel();
    _section = section;
    notifyListeners();
    unawaited(_save());
  }

  void resizeSidebar(double width) {
    final next = SettingsNavigation.clamped(
      section: _section,
      sidebarWidth: width,
    ).sidebarWidth;
    if (next == _sidebarWidth) {
      return;
    }
    _sidebarWidth = next;
    if (!_isResizingSidebar) {
      _scheduleSave();
    }
    notifyListeners();
  }

  void setSidebarResizing(bool value) {
    if (_isResizingSidebar == value) {
      return;
    }
    _isResizingSidebar = value;
    if (!value) {
      _scheduleSave();
    }
    notifyListeners();
  }

  void _scheduleSave() {
    _pendingSave?.cancel();
    _pendingSave = Timer(const Duration(milliseconds: 250), () {
      unawaited(_save());
    });
  }

  Future<void> _save() async {
    try {
      await _repository.save(
        SettingsNavigation(section: _section, sidebarWidth: _sidebarWidth),
      );
    } on Object {
      // Keep the in-session selection even if disk write fails.
    }
  }

  @override
  void dispose() {
    _pendingSave?.cancel();
    super.dispose();
  }
}
