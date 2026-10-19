import '../models/settings_navigation.dart';

abstract interface class SettingsNavigationRepository {
  Future<SettingsNavigation> load();
  Future<void> save(SettingsNavigation navigation);
}
