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
      final immersive = viewModel.ui.immersiveStatusBar;
      final children = [
        ZephyrSettingsSwitchTile(
          title: compact ? '沉浸式通知栏' : 'Immersive status bar',
          subtitle: compact
              ? '开启后应用延伸到透明通知栏下（控件仍留白），正文可上滑进入该区域。'
              : 'Draw under a transparent status bar (chrome stays padded); '
                    'text may scroll into that band.',
          value: immersive,
          onChanged: viewModel.updateImmersiveStatusBar,
        ),
        ZephyrSettingsSwitchTile(
          title: compact ? '隐藏通知栏图标' : 'Hide status bar icons',
          subtitle: compact
              ? '仅在沉浸式通知栏开启时生效；图标自动隐藏，边缘滑动可临时显示。'
              : 'Only when immersive is on. Icons auto-hide; swipe from the '
                    'edge to peek.',
          value: viewModel.ui.hideStatusBarIcons,
          showDivider: false,
          onChanged: immersive ? viewModel.updateHideStatusBarIcons : null,
        ),
      ];

      if (compact) {
        return ZephyrSettingsSection(children: children);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        children: [
          Text(
            'General',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ZephyrSettingsSection(children: children),
        ],
      );
    },
  );
}
