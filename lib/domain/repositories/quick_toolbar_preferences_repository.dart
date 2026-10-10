import '../models/quick_toolbar_config.dart';

abstract interface class QuickToolbarPreferencesRepository {
  Future<QuickToolbarConfig> load();
  Future<void> save(QuickToolbarConfig config);
}
