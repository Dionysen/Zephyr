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
            ? '开启后自动隐藏系统状态栏；正文上滑可进入通知栏区域。关闭则为透明状态栏并显示系统图标。'
            : 'On: auto-hide the system status bar; text may scroll under '
                  'it. Off: transparent status bar with system icons.',
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
