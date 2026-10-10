import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/models/library_backup.dart';
import '../../../../domain/repositories/backup_preferences_repository.dart';
import '../../../../domain/repositories/writing_library_repository.dart';
import '../../editor/view_models/library_view_model.dart';

class BackupViewModel extends ChangeNotifier {
  BackupViewModel({
    required LibraryViewModel library,
    required BackupPreferencesRepository preferencesRepository,
  }) : _library = library,
       _preferencesRepository = preferencesRepository;

  final LibraryViewModel _library;
  final BackupPreferencesRepository _preferencesRepository;

  BackupPreferences _preferences = BackupPreferences.defaults;
  List<BackupEntry> _backups = const [];
  Object? _error;
  var _busy = false;
  String? _statusMessage;

  BackupPreferences get preferences => _preferences;
  List<BackupEntry> get backups => _backups;
  Object? get error => _error;
  bool get busy => _busy;
  String? get statusMessage => _statusMessage;
  bool get autoBackupEnabled => _preferences.autoBackupEnabled;

  WritingLibraryRepository get _repository => _library.repository;

  Future<void> load() async {
    _preferences = await _preferencesRepository.load();
    await refreshBackups();
    notifyListeners();
  }

  Future<void> refreshBackups() async {
    try {
      _backups = await _repository.listBackups();
      _error = null;
    } on Object catch (error) {
      _error = error;
      _backups = const [];
    }
    notifyListeners();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(autoBackupEnabled: enabled);
    await _preferencesRepository.save(_preferences);
    notifyListeners();
  }

  Future<void> backupNow({BackupKind kind = BackupKind.manual}) async {
    if (_busy) return;
    _busy = true;
    _statusMessage = null;
    _error = null;
    notifyListeners();
    try {
      await _library.flushPending();
      await _repository.createBackup(kind: kind);
      if (kind == BackupKind.automatic) {
        _preferences = _preferences.copyWith(lastAutoBackupAt: DateTime.now());
        await _preferencesRepository.save(_preferences);
      }
      _library.markBackupCompleted();
      await refreshBackups();
      _statusMessage = 'ok';
    } on Object catch (error) {
      _error = error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> restore({
    required BackupEntry entry,
    required RestoreMode mode,
  }) async {
    if (_busy) return;
    _busy = true;
    _statusMessage = null;
    _error = null;
    notifyListeners();
    try {
      await _library.flushPending();
      await _repository.restoreBackup(entry: entry, mode: mode);
      await _library.load();
      await refreshBackups();
      _statusMessage = 'restored';
    } on Object catch (error) {
      _error = error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Call when the app leaves the foreground after edits.
  Future<void> maybeAutoBackupOnLeave() async {
    if (!_preferences.autoBackupEnabled) return;
    if (!_library.contentDirtySinceBackup) return;
    if (_library.isReadOnly) return;
    if (_busy) return;
    await backupNow(kind: BackupKind.automatic);
  }
}
