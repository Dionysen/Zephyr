import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/cloud_sync.dart';
import '../../../../domain/models/library_backup.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_snackbar.dart';
import '../view_models/backup_view_model.dart';
import '../view_models/cloud_sync_view_model.dart';

class BackupSettingsView extends StatelessWidget {
  const BackupSettingsView({
    super.key,
    required this.viewModel,
    this.compact = false,
  });

  final BackupViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cloudSync = ZephyrScope.of(context).cloudSync;
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, cloudSync]),
      builder: (context, _) {
        final l10n = context.l10n;
        final localSection = ZephyrSettingsSection(
          icon: Icons.folder_outlined,
          title: l10n.backupGroupLocalTitle,
          children: [
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
          ],
        );

        final cloudSection = ZephyrSettingsSection(
          icon: Icons.cloud_outlined,
          title: l10n.backupGroupCloudTitle,
          children: _cloudSyncTiles(context, cloudSync),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [localSection, cloudSection],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
          children: [
            Text(
              l10n.settingsSectionCloud,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            localSection,
            cloudSection,
          ],
        );
      },
    );
  }

  List<Widget> _cloudSyncTiles(
    BuildContext context,
    CloudSyncViewModel cloudSync,
  ) {
    final l10n = context.l10n;
    final signedIn = cloudSync.isSignedIn;
    final name = cloudSync.session?.username.trim();
    final last = cloudSync.preferences.lastSyncAt;
    final lastLabel = last == null
        ? l10n.cloudSyncLastSyncNever
        : l10n.cloudSyncLastSync(
            DateFormat.yMMMd().add_Hm().format(last.toLocal()),
          );

    if (!signedIn) {
      return [
        ZephyrSettingsListTile(
          icon: Icons.login,
          title: l10n.cloudSyncLoginTitle,
          subtitle: l10n.cloudSyncLoginSubtitle,
          showDivider: false,
          enabled: !cloudSync.busy,
          onTap: () => _showCredentialsDialog(context, cloudSync),
          trailing: cloudSync.isLoggingIn
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
    }

    return [
      ZephyrSettingsListTile(
        icon: Icons.cloud_upload_outlined,
        title: l10n.cloudSyncBackupNowTitle,
        subtitle: l10n.cloudSyncBackupNowSubtitle,
        enabled: !cloudSync.busy,
        onTap: () async {
          await cloudSync.backupNow();
          if (!context.mounted) return;
          final error = cloudSync.error;
          ZephyrSnackBar.show(
            context,
            error == null
                ? l10n.cloudSyncBackupNowSuccess
                : cloudSync.errorMessage(l10n)!,
          );
        },
        trailing: cloudSync.isBackingUp
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      ZephyrSettingsListTile(
        icon: Icons.cloud_download_outlined,
        title: l10n.cloudSyncRestoreTitle,
        subtitle: l10n.cloudSyncRestoreSubtitle,
        enabled: !cloudSync.busy,
        onTap: () => showCloudBackupRestoreFlow(context, cloudSync),
        trailing: cloudSync.isRestoring
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
      ZephyrSettingsSwitchTile(
        icon: Icons.sync_outlined,
        title: l10n.cloudSyncAutoTitle,
        subtitle: '$lastLabel\n${l10n.cloudSyncAutoSubtitle}',
        value: cloudSync.autoSyncEnabled,
        onChanged: cloudSync.busy
            ? null
            : (value) => cloudSync.setAutoSyncEnabled(value),
      ),
      ZephyrSettingsListTile(
        icon: Icons.logout,
        title: l10n.cloudSyncLogoutTitle,
        subtitle: l10n.cloudSyncSubtitleSignedIn(
          (name == null || name.isEmpty) ? '坚果云' : name,
        ),
        showDivider: false,
        enabled: !cloudSync.busy,
        onTap: () => cloudSync.signOut(),
      ),
    ];
  }
}

Future<void> _showCredentialsDialog(
  BuildContext context,
  CloudSyncViewModel cloudSync,
) async {
  final l10n = context.l10n;
  final urlController = TextEditingController(
    text: 'https://dav.jianguoyun.com/dav/',
  );
  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cloudSyncCredentialsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.cloudSyncCredentialsSubtitle),
          const SizedBox(height: 12),
          TextField(
            controller: accountController,
            decoration: InputDecoration(labelText: l10n.cloudSyncClientIdLabel),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: l10n.cloudSyncServerUrlLabel,
            ),
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: l10n.cloudSyncClientSecretLabel,
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.cloudSyncCredentialsSave),
        ),
      ],
    ),
  );
  if (saved != true) {
    urlController.dispose();
    accountController.dispose();
    passwordController.dispose();
    return;
  }
  await cloudSync.connect(
    serverUrl: urlController.text,
    username: accountController.text,
    appPassword: passwordController.text,
  );
  urlController.dispose();
  accountController.dispose();
  passwordController.dispose();
  if (!context.mounted) return;
  ZephyrSnackBar.show(
    context,
    cloudSync.error == null
        ? l10n.cloudSyncCredentialsSaved
        : cloudSync.errorMessage(l10n)!,
  );
}

/// Pick a cloud backup, choose merge/overwrite, confirm, then restore.
Future<void> showCloudBackupRestoreFlow(
  BuildContext context,
  CloudSyncViewModel cloudSync,
) async {
  final l10n = context.l10n;
  await cloudSync.refreshCloudBackups();
  if (!context.mounted) return;
  if (cloudSync.error != null && cloudSync.cloudBackups.isEmpty) {
    ZephyrSnackBar.show(
      context,
      cloudSync.errorMessage(l10n)!,
    );
    return;
  }
  if (cloudSync.cloudBackups.isEmpty) {
    ZephyrSnackBar.show(context, l10n.cloudSyncRestoreEmpty);
    return;
  }

  final entry = await showModalBottomSheet<CloudBackupEntry>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _CloudBackupListSheet(backups: cloudSync.cloudBackups),
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

  await cloudSync.restoreCloudBackup(entry: entry, mode: mode);
  if (!context.mounted) return;
  final error = cloudSync.error;
  ZephyrSnackBar.show(
    context,
    error == null
        ? l10n.cloudSyncRestoreSuccess
        : cloudSync.errorMessage(l10n)!,
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
    builder: (context) => _BackupListSheet(backups: viewModel.backups),
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
    final format = DateFormat.yMMMd().add_Hm();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.backupRestoreTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final entry = backups[index];
                  final kind = entry.kind == BackupKind.automatic
                      ? l10n.backupKindAuto
                      : l10n.backupKindManual;
                  return ListTile(
                    title: Text(entry.fileName),
                    subtitle: Text(
                      '$kind · ${format.format(entry.modified.toLocal())}',
                    ),
                    onTap: () => Navigator.pop(context, entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudBackupListSheet extends StatelessWidget {
  const _CloudBackupListSheet({required this.backups});

  final List<CloudBackupEntry> backups;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = DateFormat.yMMMd().add_Hm();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cloudSyncRestoreTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final entry = backups[index];
                  return ListTile(
                    title: Text(entry.fileName),
                    subtitle: Text(format.format(entry.modified.toLocal())),
                    onTap: () => Navigator.pop(context, entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
