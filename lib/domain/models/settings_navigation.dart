import 'settings_section.dart';

class SettingsNavigation {
  const SettingsNavigation({required this.section, required this.sidebarWidth});

  static const minSidebarWidth = 200.0;
  static const maxSidebarWidth = 420.0;
  static const defaultSidebarWidth = 250.0;
  static const defaults = SettingsNavigation(
    section: SettingsSection.theme,
    sidebarWidth: defaultSidebarWidth,
  );

  final SettingsSection section;
  final double sidebarWidth;

  factory SettingsNavigation.clamped({
    required SettingsSection section,
    required double sidebarWidth,
  }) => SettingsNavigation(
    section: section,
    sidebarWidth: sidebarWidth
        .clamp(minSidebarWidth, maxSidebarWidth)
        .toDouble(),
  );

  SettingsNavigation copyWith({
    SettingsSection? section,
    double? sidebarWidth,
  }) => SettingsNavigation(
    section: section ?? this.section,
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
  );
}
