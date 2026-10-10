import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/library_backup.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_snackbar.dart';
import '../view_models/backup_view_model.dart';

class BackupSettingsView extends StatelessWidget {
  const BackupSettingsView({
    super.key,
    required this.viewModel,
    this.compact = false,
  });

  final BackupViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final children = <Widget>[
        ZephyrSettingsSwitchTile(
          icon: Icons.schedule_outlined,
          title: l10n.backupAutoTitle,
          subtitle: l10n.backupAutoSubtitle,
          value: viewModel.autoBackupEnabled,
          onChanged: viewModel.busy
              ? null
              : (value) => viewModel.setAutoBackupEnabled(value),
        ),
        ZephyrSettingsListTile(
          icon: Icons.backup_outlined,
          title: l10n.backupNowTitle,
          subtitle: l10n.backupNowSubtitle,
          enabled: !viewModel.busy,
          onTap: () async {
            await viewModel.backupNow();
            if (!context.mounted) return;
            final error = viewModel.error;
            ZephyrSnackBar.show(
              context,
              error == null
                  ? l10n.backupNowSuccess
                  : l10n.backupFailed(error.toString()),
            );
          },
          trailing: viewModel.isBackingUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        ZephyrSettingsListTile(
          icon: Icons.restore,
          title: l10n.backupRestoreTitle,
          subtitle: viewModel.backups.isEmpty
              ? l10n.backupRestoreEmpty
              : l10n.backupRestoreSubtitle(viewModel.backups.length),
          showDivider: false,
          enabled: !viewModel.busy && viewModel.backups.isNotEmpty,
          onTap: () => showBackupRestoreFlow(context, viewModel),
          trailing: viewModel.isRestoring
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ];

      final section = ZephyrSettingsSection(children: children);

      if (compact) return section;

      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        children: [
          Text(
            l10n.settingsSectionCloud,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          section,
        ],
      );
    },
  );
}

/// Pick a backup, choose merge/overwrite, confirm, then restore.
Future<void> showBackupRestoreFlow(
  BuildContext context,
  BackupViewModel viewModel,
) async {
  final l10n = context.l10n;
  await viewModel.refreshBackups();
  if (!context.mounted) return;
  if (viewModel.backups.isEmpty) {
    ZephyrSnackBar.show(context, l10n.backupRestoreEmpty);
    return;
  }

  final entry = await showModalBottomSheet<BackupEntry>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BackupListSheet(
      backups: viewModel.backups,
    ),
  );
  if (entry == null || !context.mounted) return;

  final mode = await showZephyrSettingsChoicePicker<RestoreMode>(
    context,
    title: l10n.backupRestoreModeTitle,
    selected: RestoreMode.merge,
    choices: [
      ZephyrSettingsChoice(
        value: RestoreMode.merge,
        label: l10n.backupRestoreModeMerge,
      ),
      ZephyrSettingsChoice(
        value: RestoreMode.overwrite,
        label: l10n.backupRestoreModeOverwrite,
      ),
    ],
  );
  if (mode == null || !context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.backupRestoreConfirmTitle),
      content: Text(
        mode == RestoreMode.overwrite
            ? l10n.backupRestoreConfirmOverwrite
            : l10n.backupRestoreConfirmMerge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.backupRestoreAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await viewModel.restore(entry: entry, mode: mode);
  if (!context.mounted) return;
  final error = viewModel.error;
  ZephyrSnackBar.show(
    context,
    error == null
        ? l10n.backupRestoreSuccess
        : l10n.backupFailed(error.toString()),
  );
}

class _BackupListSheet extends StatelessWidget {
  const _BackupListSheet({required this.backups});

  final List<BackupEntry> backups;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final format = DateFormat.yMMMd().add_Hm();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: ZephyrBottomSheet.listTheme(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: ZephyrBottomSheet.titlePadding,
                child: Text(
                  l10n.backupRestoreTitle,
                  style: ZephyrBottomSheet.titleStyle(theme),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final entry = backups[index];
                    final kindLabel = entry.kind == BackupKind.automatic
                        ? l10n.backupKindAuto
                        : l10n.backupKindManual;
                    final sizeKb = (entry.sizeBytes / 1024).round();
                    return ZephyrBottomSheet.withRowDivider(
                      context: context,
                      showDivider: index < backups.length - 1,
                      child: ListTile(
                        title: Text(entry.fileName),
                        subtitle: Text(
                          '$kindLabel · ${format.format(entry.modified)} · $sizeKb KB',
                        ),
                        onTap: () => Navigator.pop(context, entry),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
