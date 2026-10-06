import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/settings_navigation.dart';
import 'package:zephyr/domain/models/settings_section.dart';
import 'package:zephyr/domain/repositories/settings_navigation_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/settings_view_model.dart';

void main() {
  test('loads the last selected settings group and sidebar width', () async {
    final model = SettingsViewModel(
      _SettingsRepository(
        const SettingsNavigation(
          section: SettingsSection.editor,
          sidebarWidth: 312,
        ),
      ),
    );

    await model.load();

    expect(model.section, SettingsSection.editor);
    expect(model.sidebarWidth, 312);
  });

  test('selecting a group persists it for the next open', () async {
    final repository = _SettingsRepository(SettingsNavigation.defaults);
    final model = SettingsViewModel(repository);

    model.select(SettingsSection.editor);
    await Future<void>.delayed(Duration.zero);

    expect(model.section, SettingsSection.editor);
    expect(repository.navigation.section, SettingsSection.editor);
    expect(
      repository.navigation.sidebarWidth,
      SettingsNavigation.defaultSidebarWidth,
    );
  });

  test('resizing the sidebar persists the width after the drag ends', () async {
    final repository = _SettingsRepository(SettingsNavigation.defaults);
    final model = SettingsViewModel(repository);

    model.setSidebarResizing(true);
    model.resizeSidebar(360);
    expect(
      repository.navigation.sidebarWidth,
      SettingsNavigation.defaultSidebarWidth,
    );

    model.setSidebarResizing(false);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(model.sidebarWidth, 360);
    expect(repository.navigation.sidebarWidth, 360);
  });
}

class _SettingsRepository implements SettingsNavigationRepository {
  _SettingsRepository(this.navigation);

  SettingsNavigation navigation;

  @override
  Future<SettingsNavigation> load() async => navigation;

  @override
  Future<void> save(SettingsNavigation navigation) async {
    this.navigation = navigation;
  }
}
