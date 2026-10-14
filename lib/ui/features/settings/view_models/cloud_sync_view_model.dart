import 'package:flutter/foundation.dart';

import '../../../../data/services/cloud_sync_service.dart';
import '../../../../domain/models/cloud_sync.dart';
import '../../../../domain/models/library_backup.dart';
import '../../../../l10n/app_localizations.dart';
import '../../editor/view_models/library_view_model.dart';

enum CloudSyncBusyKind { none, login, sync, backup, restore }

/// UI state for WebDAV connection, cloud backups, and auto sync.
class CloudSyncViewModel extends ChangeNotifier {
  CloudSyncViewModel({required this.library, CloudSyncService? service})
    : _service = service ?? CloudSyncService();

  final LibraryViewModel library;
  final CloudSyncService _service;

  Object? _error;
  var _busyKind = CloudSyncBusyKind.none;
  List<CloudBackupEntry> _cloudBackups = const [];

  Object? get error => _error;
  String? errorMessage(AppLocalizations l10n) {
    final error = _error;
    if (error == null) return null;
    if (error is CloudLibraryConflictException) {
      return switch (error.reason) {
        CloudLibraryConflictReason.anotherLibrary =>
          l10n.cloudSyncAnotherLibrary,
        CloudLibraryConflictReason.missingManifest =>
          l10n.cloudSyncMissingManifest,
      };
    }
    return l10n.cloudSyncFailed(error.toString());
  }
  bool get busy => _busyKind != CloudSyncBusyKind.none;
  bool get isLoggingIn => _busyKind == CloudSyncBusyKind.login;
  bool get isSyncing => _busyKind == CloudSyncBusyKind.sync;
  bool get isBackingUp => _busyKind == CloudSyncBusyKind.backup;
  bool get isRestoring => _busyKind == CloudSyncBusyKind.restore;
  bool get isSignedIn => _service.isSignedIn;
  CloudSyncSession? get session => _service.session;
  CloudSyncPreferences get preferences => _service.preferences;
  bool get autoSyncEnabled => _service.preferences.autoSyncEnabled;
  List<CloudBackupEntry> get cloudBackups => _cloudBackups;

  Future<void> load() async {
    try {
      await _service.load();
      _error = null;
    } on Object catch (error) {
      _error = error;
    }
    notifyListeners();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _service.setAutoSyncEnabled(enabled);
    notifyListeners();
  }

  Future<void> connect({
    required String serverUrl,
    required String username,
    required String appPassword,
  }) async {
    if (busy) return;
    _busyKind = CloudSyncBusyKind.login;
    _error = null;
    notifyListeners();
    try {
      await _service.connect(
        CloudSyncSession(
          serverUrl: serverUrl.trim(),
          username: username.trim(),
          appPassword: appPassword,
        ),
      );
    } on Object catch (error) {
      _error = error;
    } finally {
      _busyKind = CloudSyncBusyKind.none;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _cloudBackups = const [];
    notifyListeners();
  }

  Future<void> backupNow() async {
    if (busy) return;
    if (!isSignedIn) {
      _error = StateError('Not signed in.');
      notifyListeners();
      return;
    }
    _busyKind = CloudSyncBusyKind.backup;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    try {
      await _service.backupNow(
        library: library.repository,
        flushPending: library.flushPending,
      );
      library.markBackupCompleted();
      _error = null;
    } on Object catch (error) {
      _error = error;
    } finally {
      _busyKind = CloudSyncBusyKind.none;
      notifyListeners();
    }
  }

  Future<List<CloudBackupEntry>> refreshCloudBackups() async {
    if (!isSignedIn) {
      _cloudBackups = const [];
      notifyListeners();
      return _cloudBackups;
    }
    try {
      _cloudBackups = await _service.listCloudBackups(
        library: library.repository,
      );
      _error = null;
    } on Object catch (error) {
      _error = error;
      _cloudBackups = const [];
    }
    notifyListeners();
    return _cloudBackups;
  }

  Future<void> restoreCloudBackup({
    required CloudBackupEntry entry,
    required RestoreMode mode,
  }) async {
    if (busy) return;
    _busyKind = CloudSyncBusyKind.restore;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    try {
      await _service.restoreCloudBackup(
        library: library.repository,
        entry: entry,
        mode: mode,
        flushPending: library.flushPending,
      );
      await library.load();
      _error = null;
    } on Object catch (error) {
      _error = error;
    } finally {
      _busyKind = CloudSyncBusyKind.none;
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    if (busy) return;
    if (!isSignedIn) {
      _error = StateError('Not signed in.');
      notifyListeners();
      return;
    }
    _busyKind = CloudSyncBusyKind.sync;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    try {
      await _service.syncNow(
        library: library.repository,
        flushPending: library.flushPending,
      );
      await library.load();
      _error = null;
    } on Object catch (error) {
      _error = error;
    } finally {
      _busyKind = CloudSyncBusyKind.none;
      notifyListeners();
    }
  }

  /// Call when the app resumes / pauses (fire-and-forget).
  Future<void> maybeAutoSync() async {
    if (!autoSyncEnabled) return;
    if (!isSignedIn) return;
    if (library.isReadOnly) return;
    if (busy) return;
    await syncNow();
  }
}
