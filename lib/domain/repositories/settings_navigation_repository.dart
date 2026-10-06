import '../models/settings_section.dart';

abstract interface class SettingsNavigationRepository {
  Future<SettingsSection> load();
  Future<void> save(SettingsSection section);
}
