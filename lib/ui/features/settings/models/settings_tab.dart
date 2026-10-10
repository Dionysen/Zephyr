import 'package:flutter/material.dart';

import '../../../../domain/models/settings_section.dart';
import '../../../core/zephyr_l10n.dart';

/// Top-level settings pages shown in the floating tab bar.
enum SettingsTab { general, editor, appearance, about }

extension SettingsTabLabels on SettingsTab {
  String title(AppLocalizations l10n) => switch (this) {
    SettingsTab.general => l10n.settingsSectionGeneral,
    SettingsTab.editor => l10n.settingsSectionEditor,
    SettingsTab.appearance => l10n.settingsSectionTheme,
    SettingsTab.about => l10n.settingsSectionAbout,
  };

  IconData get icon => switch (this) {
    SettingsTab.general => Icons.tune,
    SettingsTab.editor => Icons.edit_outlined,
    SettingsTab.appearance => Icons.palette_outlined,
    SettingsTab.about => Icons.info_outline,
  };

  /// Canonical [SettingsSection] used when persisting this tab.
  SettingsSection get storageSection => switch (this) {
    SettingsTab.general => SettingsSection.general,
    SettingsTab.editor => SettingsSection.editor,
    SettingsTab.appearance => SettingsSection.theme,
    SettingsTab.about => SettingsSection.about,
  };

  /// Maps a stored section (including legacy subsections) onto a tab.
  static SettingsTab fromSection(SettingsSection section) => switch (section) {
    SettingsSection.general || SettingsSection.cloud => SettingsTab.general,
    SettingsSection.editor || SettingsSection.shortcuts => SettingsTab.editor,
    SettingsSection.theme => SettingsTab.appearance,
    SettingsSection.about => SettingsTab.about,
  };
}
