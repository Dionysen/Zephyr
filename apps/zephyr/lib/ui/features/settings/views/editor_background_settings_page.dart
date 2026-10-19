import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import 'editor_background_settings_view.dart';

/// Nested settings route for one mode's editor background.
class EditorBackgroundSettingsPage extends StatelessWidget {
  const EditorBackgroundSettingsPage({super.key, required this.dark});

  final bool dark;

  static Route<void> route({required bool dark}) => MaterialPageRoute<void>(
    builder: (_) => EditorBackgroundSettingsPage(dark: dark),
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
                title: dark
                    ? l10n.editorBackgroundDarkTitle
                    : l10n.editorBackgroundLightTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Expanded(
            child: EditorBackgroundSettingsView(
              viewModel: scope.theme,
              dark: dark,
            ),
          ),
        ],
      ),
    );
  }
}
