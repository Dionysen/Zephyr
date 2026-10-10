import '../../domain/models/library_backup.dart';
import '../../domain/repositories/backup_preferences_repository.dart';
import '../services/backup_preferences_file_storage.dart';

class FileBackupPreferencesRepository implements BackupPreferencesRepository {
  FileBackupPreferencesRepository(this._storage);

  final BackupPreferencesFileStorage _storage;

  @override
  Future<BackupPreferences> load() => _storage.load();

  @override
  Future<void> save(BackupPreferences preferences) => _storage.save(preferences);
}
