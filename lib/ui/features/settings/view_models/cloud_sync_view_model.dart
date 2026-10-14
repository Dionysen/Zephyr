import 'package:flutter/foundation.dart';

import '../../../../data/services/cloud_sync_service.dart';
import '../../../../domain/models/cloud_sync.dart';
import '../../../../domain/models/library_backup.dart';
import '../../../../l10n/app_localizations.dart';
import '../../editor/view_models/library_view_model.dart';

enum CloudSyncBusyKind { none, login, sync, backup, restore }

/// UI state for WebDAV connection, cloud backups, and auto sync.
class CloudSyncViewModel extends ChangeNotifier {
  CloudSyncViewModel({
    required this.library,
    CloudSyncService? service,
    this._reloadLocalSettings,
  }) : _service = service ?? CloudSyncService();

  final LibraryViewModel library;
  final CloudSyncService _service;
  final Future<void> Function()? _reloadLocalSettings;

  Object? _error;
  var _busyKind = CloudSyncBusyKind.none;
  List<CloudBackupEntry> _cloudBackups = const [];
  CloudPullResult? _lastPullResult;

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
  bool get cloudBackupEnabled => _service.cloudBackupEnabled;
  CloudSyncSession? get session => _service.session;
  CloudSyncPreferences get preferences => _service.preferences;
  bool get autoSyncEnabled => _service.preferences.autoSyncEnabled;
  List<CloudBackupEntry> get cloudBackups => _cloudBackups;
  CloudPullResult? get lastPullResult => _lastPullResult;

  Future<void> load() async {
    try {
      await _service.load();
      _error = null;
    } on Object catch (error) {
      _error = error;
    }
    notifyListeners();
  }

  Future<void> setCloudBackupEnabled(bool enabled) async {
    await _service.setCloudBackupEnabled(enabled);
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
    if (!cloudBackupEnabled || !isSignedIn) {
      _error = StateError('Cloud backup is not ready.');
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
    if (!cloudBackupEnabled || !isSignedIn) {
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
    if (!cloudBackupEnabled || !isSignedIn) {
      _error = StateError('Cloud backup is not ready.');
      notifyListeners();
      return;
    }
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
      await _reloadLocalSettings?.call();
      _error = null;
    } on Object catch (error) {
      _error = error;
    } finally {
      _busyKind = CloudSyncBusyKind.none;
      notifyListeners();
    }
  }

  Future<CloudPullResult?> syncNow() async {
    if (busy) return null;
    if (!cloudBackupEnabled || !isSignedIn) {
      _error = StateError('Cloud backup is not ready.');
      notifyListeners();
      return null;
    }
    _busyKind = CloudSyncBusyKind.sync;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    try {
      final result = await _service.pullIfNewer(
        library: library.repository,
        flushPending: library.flushPending,
      );
      _lastPullResult = result;
      if (result.pulled) {
        await library.load();
      }
      // Settings may refresh even when the library snapshot was skipped.
      await _reloadLocalSettings?.call();
      _error = null;
      return result;
    } on Object catch (error) {
      _error = error;
      return null;
    } finally {
      _busyKind = CloudSyncBusyKind.none;
      notifyListeners();
    }
  }

  /// Open / resume: pull-merge newer cloud snapshot only (no upload).
  Future<CloudPullResult?> maybeAutoSync() async {
    if (!cloudBackupEnabled) return null;
    if (!autoSyncEnabled) return null;
    if (!isSignedIn) return null;
    if (library.isReadOnly) return null;
    if (busy) return null;
    return syncNow();
  }

  /// Mobile background / leave: upload when cloud backup is on and content
  /// changed since the last backup (same dirty gate as local auto-backup).
  ///
  /// Creates one local automatic `.pwb` then uploads it — mirrors desktop exit
  /// upload, but only when there is something new (pause is frequent).
  /// Returns `true` when an upload was attempted (check [error] for failure).
  Future<bool> maybeUploadOnLeave() async {
    if (!cloudBackupEnabled || !isSignedIn) return false;
    if (library.isReadOnly) return false;
    if (!library.contentDirtySinceBackup) return false;
    if (busy) return false;
    await backupNow();
    return true;
  }
}
