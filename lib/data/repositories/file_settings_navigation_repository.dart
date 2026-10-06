import '../../domain/models/settings_navigation.dart';
import '../../domain/models/settings_section.dart';
import '../../domain/repositories/settings_navigation_repository.dart';
import '../services/settings_navigation_file_storage.dart';

class FileSettingsNavigationRepository implements SettingsNavigationRepository {
  FileSettingsNavigationRepository(this._storage);

  final SettingsNavigationFileStorage _storage;

  @override
  Future<SettingsNavigation> load() async {
    final values = await _storage.read();
    if (values == null) {
      return SettingsNavigation.defaults;
    }
    final name = values['section'];
    final width = values['sidebarWidth'];
    return SettingsNavigation.clamped(
      section:
          SettingsSection.values
              .where((section) => section.name == name)
              .firstOrNull ??
          SettingsSection.theme,
      sidebarWidth: width is num
          ? width.toDouble()
          : SettingsNavigation.defaultSidebarWidth,
    );
  }

  @override
  Future<void> save(SettingsNavigation navigation) => _storage.write({
    'section': navigation.section.name,
    'sidebarWidth': navigation.sidebarWidth,
  });
}
