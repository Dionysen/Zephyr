import 'package:flutter/material.dart';

import '../../../../domain/models/settings_section.dart';
import '../../../core/zephyr_l10n.dart';

/// Top-level settings pages shown in the floating tab bar.
enum SettingsTab { general, editor, appearance, backup, about }

extension SettingsTabLabels on SettingsTab {
  String title(AppLocalizations l10n) => switch (this) {
    SettingsTab.general => l10n.settingsSectionGeneral,
    SettingsTab.backup => l10n.settingsSectionCloud,
    SettingsTab.editor => l10n.settingsSectionEditor,
    SettingsTab.appearance => l10n.settingsSectionTheme,
    SettingsTab.about => l10n.settingsSectionAbout,
  };

  IconData get icon => switch (this) {
    SettingsTab.general => Icons.tune,
    SettingsTab.backup => Icons.backup_outlined,
    SettingsTab.editor => Icons.edit_outlined,
    SettingsTab.appearance => Icons.palette_outlined,
    SettingsTab.about => Icons.info_outline,
  };

  /// Canonical [SettingsSection] used when persisting this tab.
  SettingsSection get storageSection => switch (this) {
    SettingsTab.general => SettingsSection.general,
    SettingsTab.backup => SettingsSection.cloud,
    SettingsTab.editor => SettingsSection.editor,
    SettingsTab.appearance => SettingsSection.theme,
    SettingsTab.about => SettingsSection.about,
  };

  /// Maps a stored section (including legacy subsections) onto a tab.
  static SettingsTab fromSection(SettingsSection section) => switch (section) {
    SettingsSection.general => SettingsTab.general,
    SettingsSection.cloud => SettingsTab.backup,
    SettingsSection.editor || SettingsSection.shortcuts => SettingsTab.editor,
    SettingsSection.theme => SettingsTab.appearance,
    SettingsSection.about => SettingsTab.about,
  };
}
