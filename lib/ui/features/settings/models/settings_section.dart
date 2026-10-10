import 'package:flutter/material.dart';

import '../../../../domain/models/settings_section.dart';
import '../../../core/zephyr_l10n.dart';

export '../../../../domain/models/settings_section.dart';

extension SettingsSectionLabels on SettingsSection {
  String title(AppLocalizations l10n) => switch (this) {
    SettingsSection.general => l10n.settingsSectionGeneral,
    SettingsSection.cloud => l10n.settingsSectionCloud,
    SettingsSection.editor => l10n.settingsSectionEditor,
    SettingsSection.shortcuts => l10n.settingsSectionShortcuts,
    SettingsSection.theme => l10n.settingsSectionTheme,
    SettingsSection.about => l10n.settingsSectionAbout,
  };

  IconData get icon => switch (this) {
    SettingsSection.general => Icons.tune,
    SettingsSection.cloud => Icons.backup_outlined,
    SettingsSection.editor => Icons.edit_outlined,
    SettingsSection.shortcuts => Icons.keyboard_outlined,
    SettingsSection.theme => Icons.palette_outlined,
    SettingsSection.about => Icons.info_outline,
  };
}
