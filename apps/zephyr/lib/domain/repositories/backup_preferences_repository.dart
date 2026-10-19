import '../models/library_backup.dart';

abstract interface class BackupPreferencesRepository {
  Future<BackupPreferences> load();
  Future<void> save(BackupPreferences preferences);
}
