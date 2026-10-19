import 'package:flutter/material.dart';

import '../chrome_controls.dart';
import 'settings_list_tile.dart';

/// Horizontal settings row with a Material [Switch] as the only control.
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
      // Always Material (not Cupertino / platform-adaptive); M3 track size is
      // fixed, so scale for denser settings chrome.
      trailing: Transform.scale(
        scale: ChromeControls.settingsSwitchScale,
        alignment: Alignment.centerRight,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
