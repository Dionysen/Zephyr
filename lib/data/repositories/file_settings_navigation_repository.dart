import '../../domain/models/settings_section.dart';
import '../../domain/repositories/settings_navigation_repository.dart';
import '../services/settings_navigation_file_storage.dart';

class FileSettingsNavigationRepository implements SettingsNavigationRepository {
  FileSettingsNavigationRepository(this._storage);

  final SettingsNavigationFileStorage _storage;

  @override
  Future<SettingsSection> load() async {
    final values = await _storage.read();
    if (values == null) {
      return SettingsSection.theme;
    }
    final name = values['section'];
    return SettingsSection.values
            .where((section) => section.name == name)
            .firstOrNull ??
        SettingsSection.theme;
  }

  @override
  Future<void> save(SettingsSection section) =>
      _storage.write({'section': section.name});
}
