import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/settings_section.dart';
import 'package:zephyr/domain/repositories/settings_navigation_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/settings_view_model.dart';

void main() {
  test('loads the last selected settings group', () async {
    final model = SettingsViewModel(
      _SettingsRepository(SettingsSection.editor),
    );

    await model.load();

    expect(model.section, SettingsSection.editor);
  });

  test('selecting a group persists it for the next open', () async {
    final repository = _SettingsRepository(SettingsSection.theme);
    final model = SettingsViewModel(repository);

    model.select(SettingsSection.editor);
    await Future<void>.delayed(Duration.zero);

    expect(model.section, SettingsSection.editor);
    expect(repository.section, SettingsSection.editor);
  });
}

class _SettingsRepository implements SettingsNavigationRepository {
  _SettingsRepository(this.section);

  SettingsSection section;

  @override
  Future<SettingsSection> load() async => section;

  @override
  Future<void> save(SettingsSection section) async {
    this.section = section;
  }
}
