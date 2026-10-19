import 'package:flutter/material.dart';
import 'package:flutter_primitives/settings/settings_section.dart';

import '../zephyr_theme.dart';

/// Zephyr theme adapter for the reusable settings section.
class ZephyrSettingsSection extends StatelessWidget {
  const ZephyrSettingsSection({
    super.key,
    required this.children,
    this.title,
    this.icon,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: 20),
  });

  final String? title;
  final IconData? icon;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: title,
    icon: icon,
    footer: footer,
    margin: margin,
    cornerRadius: context.zephyrCornerRadius,
    children: children,
  );
}
