import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import '../models/settings_section.dart';
import 'about_settings_view.dart';

/// Nested settings route: back returns only to the parent settings list.
class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const AboutSettingsPage(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surface = Theme.of(context).colorScheme.surface;
    final barColor = ZephyrSettingsAppBar.backgroundColor(context);
    return Material(
      color: surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: barColor,
            child: ZephyrTopSafeArea(
              bottom: false,
              child: ZephyrSettingsAppBar(
                title: SettingsSection.about.title(l10n),
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: const [
                AboutSettingsView(compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
