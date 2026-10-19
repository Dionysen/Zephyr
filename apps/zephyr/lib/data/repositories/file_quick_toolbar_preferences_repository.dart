import '../../domain/models/quick_toolbar_config.dart';
import '../../domain/repositories/quick_toolbar_preferences_repository.dart';
import '../services/quick_toolbar_file_storage.dart';

class FileQuickToolbarPreferencesRepository
    implements QuickToolbarPreferencesRepository {
  FileQuickToolbarPreferencesRepository(this._storage);
  final QuickToolbarFileStorage _storage;

  @override
  Future<QuickToolbarConfig> load() async {
    final values = await _storage.read();
    if (values == null) return QuickToolbarConfig.defaults;
    return QuickToolbarConfig.fromJson(values);
  }

  @override
  Future<void> save(QuickToolbarConfig config) =>
      _storage.write(config.normalized().toJson());
}
