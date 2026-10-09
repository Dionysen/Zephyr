import 'package:flutter/material.dart';

import '../../../core/zephyr_settings.dart';
import '../view_models/theme_view_model.dart';

class GeneralSettingsView extends StatelessWidget {
  const GeneralSettingsView({
    super.key,
    required this.viewModel,
    this.compact = false,
  });

  final ThemeViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final tile = ZephyrSettingsSwitchTile(
        title: compact ? '沉浸式通知栏' : 'Immersive status bar',
        subtitle: compact
            ? '开启后应用延伸到透明通知栏下（控件仍留白），正文可上滑进入该区域。'
            : 'On: draw under a transparent status bar (chrome stays padded); '
                  'text may scroll into that band.',
        value: viewModel.ui.immersiveStatusBar,
        showDivider: false,
        onChanged: viewModel.updateImmersiveStatusBar,
      );

      if (compact) {
        return ZephyrSettingsSection(children: [tile]);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        children: [
          Text(
            'General',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ZephyrSettingsSection(children: [tile]),
        ],
      );
    },
  );
}
