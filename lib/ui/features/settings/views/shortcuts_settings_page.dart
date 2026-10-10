import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import 'shortcuts_settings_view.dart';

/// Nested settings route: back returns only to the parent settings list.
class ShortcutsSettingsPage extends StatelessWidget {
  const ShortcutsSettingsPage({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const ShortcutsSettingsPage(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = ZephyrScope.of(context);
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
                title: l10n.settingsSectionShortcuts,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Expanded(
            child: ShortcutsSettingsView(
              viewModel: scope.keyboardShortcuts,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}
