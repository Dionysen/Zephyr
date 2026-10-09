import 'package:flutter/material.dart';

import '../zephyr_controls.dart';
import 'zephyr_settings_list_tile.dart';

/// Horizontal settings row with a Material [Switch] as the only control.
class ZephyrSettingsSwitchTile extends StatelessWidget {
  const ZephyrSettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return ZephyrSettingsListTile(
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      // Always Material (not Cupertino / platform-adaptive); M3 track size is
      // fixed, so scale for denser settings chrome.
      trailing: Transform.scale(
        scale: ZephyrControls.settingsSwitchScale,
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
