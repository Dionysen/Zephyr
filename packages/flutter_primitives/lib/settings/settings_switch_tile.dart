import 'package:flutter/material.dart';

import '../chrome_controls.dart';
import '../design/design_controls.dart';
import 'settings_list_tile.dart';

/// Horizontal settings row with a switch selected by the design style.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return SettingsListTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: DesignSwitch(
        value: value,
        onChanged: onChanged,
        materialScale: ChromeControls.settingsSwitchScale,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
