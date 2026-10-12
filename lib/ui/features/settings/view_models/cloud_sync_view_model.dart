import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/services/cloud_sync_service.dart';
import '../../../../domain/models/cloud_sync.dart';
import '../../../../domain/models/library_backup.dart';
import '../../editor/view_models/library_view_model.dart';

enum CloudSyncBusyKind { none, login, sync, backup, restore }

/// UI state for Aliyun Drive login, cloud backups, and auto sync.
class CloudSyncViewModel extends ChangeNotifier {
  CloudSyncViewModel({
    required this.library,
    CloudSyncService? service,
  }) : _service = service ?? CloudSyncService();

  final LibraryViewModel library;
  final CloudSyncService _service;

  Object? _error;
  var _busyKind = CloudSyncBusyKind.none;
  AliyunDriveQrChallenge? _qrChallenge;
  AliyunDriveQrStatus? _qrStatus;
  Timer? _qrPollTimer;
  List<CloudBackupEntry> _cloudBackups = const [];

  Object? get error => _error;
  bool get busy => _busyKind != CloudSyncBusyKind.none;
  bool get isLoggingIn => _busyKind == CloudSyncBusyKind.login;
  bool get isSyncing => _busyKind == CloudSyncBusyKind.sync;
  bool get isBackingUp => _busyKind == CloudSyncBusyKind.backup;
  bool get isRestoring => _busyKind == CloudSyncBusyKind.restore;
  bool get isSignedIn => _service.isSignedIn;
  bool get isAppConfigured => _service.isAppConfigured;
  CloudSyncSession? get session => _service.session;
  CloudSyncPreferences get preferences => _service.preferences;
  bool get autoSyncEnabled => _service.preferences.autoSyncEnabled;
  AliyunDriveQrChallenge? get qrChallenge => _qrChallenge;
  AliyunDriveQrStatus? get qrStatus => _qrStatus;
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

  Future<void> saveAppCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    await _service.saveAppCredentials(
      AliyunDriveAppCredentials(
        clientId: clientId.trim(),
        clientSecret: clientSecret.trim(),
      ),
    );
    notifyListeners();
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _service.setAutoSyncEnabled(enabled);
    notifyListeners();
  }

  Future<void> beginLogin() async {
    if (busy) return;
    _busyKind = CloudSyncBusyKind.login;
    _error = null;
    _qrChallenge = null;
    _qrStatus = null;
    notifyListeners();
    try {
      _qrChallenge = await _service.beginQrLogin();
      _qrStatus = AliyunDriveQrStatus.waiting;
      _startQrPolling();
    } on Object catch (error) {
      _error = error;
      _busyKind = CloudSyncBusyKind.none;
    }
    notifyListeners();
  }

  void cancelLogin() {
    _qrPollTimer?.cancel();
    _qrPollTimer = null;
    _qrChallenge = null;
    _qrStatus = null;
    if (_busyKind == CloudSyncBusyKind.login) {
      _busyKind = CloudSyncBusyKind.none;
    }
    notifyListeners();
  }

  void _startQrPolling() {
    _qrPollTimer?.cancel();
    final sid = _qrChallenge?.sid;
    if (sid == null) return;
    _qrPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final poll = await _service.pollQrLogin(sid);
        _qrStatus = poll.status;
        if (poll.status == AliyunDriveQrStatus.success &&
            poll.authCode != null &&
            poll.authCode!.isNotEmpty) {
          _qrPollTimer?.cancel();
          _qrPollTimer = null;
          await _service.completeQrLogin(poll.authCode!);
          _qrChallenge = null;
          _qrStatus = null;
          _busyKind = CloudSyncBusyKind.none;
          _error = null;
          notifyListeners();
          return;
        }
        if (poll.status == AliyunDriveQrStatus.expired ||
            poll.status == AliyunDriveQrStatus.failed) {
          _qrPollTimer?.cancel();
          _qrPollTimer = null;
          _busyKind = CloudSyncBusyKind.none;
          _error = StateError('Aliyun Drive QR login ${poll.status.name}.');
        }
        notifyListeners();
      } on Object catch (error) {
        _qrPollTimer?.cancel();
        _qrPollTimer = null;
        _busyKind = CloudSyncBusyKind.none;
        _error = error;
        notifyListeners();
      }
    });
  }

  Future<void> signOut() async {
    cancelLogin();
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
    unawaited(syncNow());
  }

  @override
  void dispose() {
    _qrPollTimer?.cancel();
    super.dispose();
  }
}
