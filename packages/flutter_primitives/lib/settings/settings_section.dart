import 'package:flutter/material.dart';

import 'settings_category_header.dart';

/// Grouped block of settings tiles with an optional icon + title header.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.children,
    this.title,
    this.icon,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: 20),
    this.cornerRadius = 4,
  });

  final String? title;
  final IconData? icon;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = cornerRadius;
    final dark = theme.brightness == Brightness.dark;
    // Opaque control surface: white card on light page gray; raised panel in dark.
    final fill = scheme.surfaceContainerHigh;
    // Same geometry for both modes; dark uses lower alpha so it doesn't read heavier.
    final shadowColor = scheme.shadow.withValues(alpha: dark ? 0.10 : 0.12);

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            if (icon != null)
              SettingsCategoryHeader(
                icon: icon!,
                title: title!,
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  title!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: children),
                ),
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
