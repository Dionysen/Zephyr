import 'package:flutter/material.dart';

import '../../../../domain/models/status_bar_mode.dart';
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
      final mode = viewModel.ui.statusBarMode;
      final tile = ZephyrSettingsChoiceTile<StatusBarMode>(
        title: compact ? '通知栏' : 'Status bar',
        subtitle: compact
            ? '控制状态栏显示方式；控件始终避开通知栏区域。'
            : 'How the system status bar is shown. Chrome never enters '
                  'the status-bar region.',
        selected: mode,
        valueLabel: _modeLabel(mode, compact: compact),
        choices: [
          ZephyrSettingsChoice(
            value: StatusBarMode.normal,
            label: compact ? '正常显示' : 'Normal',
            subtitle: compact
                ? '不透明状态栏，图标可见。'
                : 'Opaque status bar matching the app surface.',
          ),
          ZephyrSettingsChoice(
            value: StatusBarMode.transparent,
            label: compact ? '透明沉浸' : 'Transparent',
            subtitle: compact
                ? '全透明，露出应用背景；图标可见。'
                : 'Transparent bar; app background shows through.',
          ),
          ZephyrSettingsChoice(
            value: StatusBarMode.immersive,
            label: compact ? '自动隐藏' : 'Auto-hide',
            subtitle: compact
                ? '图标自动隐藏；正文上滑可自然进入通知栏区域，不影响滚动手感。'
                : 'Icons hide; text may scroll under the status band '
                      'without changing scroll layout.',
          ),
        ],
        showDivider: false,
        onSelected: viewModel.updateStatusBarMode,
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

String _modeLabel(StatusBarMode mode, {required bool compact}) =>
    switch (mode) {
      StatusBarMode.normal => compact ? '正常显示' : 'Normal',
      StatusBarMode.transparent => compact ? '透明沉浸' : 'Transparent',
      StatusBarMode.immersive => compact ? '自动隐藏' : 'Auto-hide',
    };
