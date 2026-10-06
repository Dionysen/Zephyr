import 'package:flutter/material.dart';

import '../../../../domain/models/settings_section.dart';

export '../../../../domain/models/settings_section.dart';

extension SettingsSectionLabels on SettingsSection {
  String get title => switch (this) {
    SettingsSection.general => 'General',
    SettingsSection.cloud => 'Cloud sync',
    SettingsSection.editor => 'Editor',
    SettingsSection.shortcuts => 'Shortcuts',
    SettingsSection.theme => 'Theme',
    SettingsSection.about => 'About',
  };

  IconData get icon => switch (this) {
    SettingsSection.general => Icons.tune,
    SettingsSection.cloud => Icons.cloud_outlined,
    SettingsSection.editor => Icons.edit_outlined,
    SettingsSection.shortcuts => Icons.keyboard_outlined,
    SettingsSection.theme => Icons.palette_outlined,
    SettingsSection.about => Icons.info_outline,
  };
}
