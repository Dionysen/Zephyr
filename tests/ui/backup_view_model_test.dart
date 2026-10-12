import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/repositories/backup_preferences_repository.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/backup_view_model.dart';

void main() {
  late _BackupRepository repository;
  late _BackupPreferencesRepository preferences;
  late LibraryViewModel library;
  late BackupViewModel model;

  setUp(() {
    repository = _BackupRepository();
    preferences = _BackupPreferencesRepository();
    library = LibraryViewModel(repository);
    model = BackupViewModel(
      library: library,
      preferencesRepository: preferences,
    );
    addTearDown(() {
      model.dispose();
      library.dispose();
    });
  });

  test('loading preferences and backup list exposes saved state', () async {
    preferences.value = const BackupPreferences(autoBackupEnabled: false);
    repository.backups = [_BackupRepository.entry];

    await model.load();

    expect(model.autoBackupEnabled, isFalse);
    expect(model.backups, [_BackupRepository.entry]);
    expect(model.error, isNull);
  });

  test(
    'failed backup discovery clears stale results and reports the error',
    () async {
      repository.backups = [_BackupRepository.entry];
      await model.refreshBackups();
      repository.failList = true;

      await model.refreshBackups();

      expect(model.backups, isEmpty);
      expect(model.error, isA<StateError>());
    },
  );

  test('changing automatic backup preference persists the selection', () async {
    await model.setAutoBackupEnabled(false);

    expect(model.autoBackupEnabled, isFalse);
    expect(preferences.value.autoBackupEnabled, isFalse);
    expect(preferences.saves, 1);
  });

  test(
    'manual backup exposes busy state and blocks a duplicate operation',
    () async {
      final pending = Completer<BackupEntry>();
      repository.pendingBackup = pending;

      final first = model.backupNow();
      expect(model.busy, isTrue);
      expect(model.isBackingUp, isTrue);
      await Future<void>.delayed(Duration.zero);
      await model.backupNow();
      expect(repository.createCalls, 1);

      pending.complete(_BackupRepository.entry);
      await first;
      expect(model.busy, isFalse);
      expect(model.statusMessage, 'ok');
      expect(model.error, isNull);
    },
  );

  test(
    'automatic backup records completion time and failure leaves an error',
    () async {
      await model.backupNow(kind: BackupKind.automatic);
      expect(preferences.value.lastAutoBackupAt, isNotNull);
      expect(repository.lastKind, BackupKind.automatic);

      repository.failCreate = true;
      await model.backupNow();
      expect(model.busy, isFalse);
      expect(model.error, isA<StateError>());
      expect(model.statusMessage, isNull);
    },
  );
}

class _BackupPreferencesRepository implements BackupPreferencesRepository {
  BackupPreferences value = BackupPreferences.defaults;
  int saves = 0;

  @override
  Future<BackupPreferences> load() async => value;

  @override
  Future<void> save(BackupPreferences value) async {
    saves++;
    this.value = value;
  }
}

class _BackupRepository implements WritingLibraryRepository {
  static final entry = BackupEntry(
    path: '/backups/one.pwb',
    fileName: 'one.pwb',
    modified: DateTime.utc(2026, 1, 1),
    sizeBytes: 10,
    kind: BackupKind.manual,
  );

  List<BackupEntry> backups = [];
  bool failList = false;
  bool failCreate = false;
  int createCalls = 0;
  BackupKind? lastKind;
  Completer<BackupEntry>? pendingBackup;

  @override
  Future<List<BackupEntry>> listBackups() async {
    if (failList) throw StateError('list failed');
    return backups;
  }

  @override
  Future<BackupEntry> createBackup({required BackupKind kind}) async {
    createCalls++;
    lastKind = kind;
    if (failCreate) throw StateError('backup failed');
    if (pendingBackup case final pending?) return pending.future;
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
