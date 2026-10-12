import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final name = cloudSync.session?.displayName.trim();
    final last = cloudSync.preferences.lastSyncAt;
    final lastLabel = last == null
        ? l10n.cloudSyncLastSyncNever
        : l10n.cloudSyncLastSync(
            DateFormat.yMMMd().add_Hm().format(last.toLocal()),
          );

    if (!signedIn) {
      return [
        if (!cloudSync.isAppConfigured)
          ZephyrSettingsListTile(
            icon: Icons.key_outlined,
            title: l10n.cloudSyncCredentialsTitle,
            subtitle: l10n.cloudSyncCredentialsSubtitle,
            enabled: !cloudSync.busy,
            onTap: () => _showCredentialsDialog(context, cloudSync),
          ),
        ZephyrSettingsListTile(
          icon: Icons.login,
          title: l10n.cloudSyncLoginTitle,
          subtitle: l10n.cloudSyncLoginSubtitle,
          showDivider: false,
          enabled: !cloudSync.busy,
          onTap: () => _startAliyunLogin(context, cloudSync),
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
                : l10n.cloudSyncFailed(error.toString()),
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
          (name == null || name.isEmpty) ? 'Aliyun Drive' : name,
        ),
        showDivider: false,
        enabled: !cloudSync.busy,
        onTap: () => cloudSync.signOut(),
      ),
    ];
  }
}

Future<void> _startAliyunLogin(
  BuildContext context,
  CloudSyncViewModel cloudSync,
) async {
  final l10n = context.l10n;
  if (!cloudSync.isAppConfigured) {
    ZephyrSnackBar.show(context, l10n.cloudSyncCredentialsMissing);
    await _showCredentialsDialog(context, cloudSync);
    if (!context.mounted || !cloudSync.isAppConfigured) return;
  }
  await cloudSync.beginLogin();
  if (!context.mounted) return;
  if (cloudSync.qrChallenge != null) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AliyunQrLoginDialog(viewModel: cloudSync),
    );
  } else if (cloudSync.error != null) {
    ZephyrSnackBar.show(
      context,
      l10n.cloudSyncFailed(cloudSync.error.toString()),
    );
  }
}

Future<void> _showCredentialsDialog(
  BuildContext context,
  CloudSyncViewModel cloudSync,
) async {
  final l10n = context.l10n;
  final idController = TextEditingController();
  final secretController = TextEditingController();
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
            controller: idController,
            decoration: InputDecoration(labelText: l10n.cloudSyncClientIdLabel),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: secretController,
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
    idController.dispose();
    secretController.dispose();
    return;
  }
  await cloudSync.saveAppCredentials(
    clientId: idController.text,
    clientSecret: secretController.text,
  );
  idController.dispose();
  secretController.dispose();
  if (!context.mounted) return;
  ZephyrSnackBar.show(context, l10n.cloudSyncCredentialsSaved);
}

class _AliyunQrLoginDialog extends StatelessWidget {
  const _AliyunQrLoginDialog({required this.viewModel});

  final CloudSyncViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final challenge = viewModel.qrChallenge;
        if (challenge == null || viewModel.isSignedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
        }
        final statusText = switch (viewModel.qrStatus) {
          AliyunDriveQrStatus.scanned => l10n.cloudSyncQrScanned,
          _ => l10n.cloudSyncQrWaiting,
        };
        return AlertDialog(
          title: Text(l10n.cloudSyncQrTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.cloudSyncQrHint),
              const SizedBox(height: 16),
              if (challenge != null)
                QrImageView(
                  data: challenge.qrCodeUrl,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              const SizedBox(height: 12),
              Text(statusText),
              if (viewModel.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  viewModel.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            if (challenge != null)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(challenge.qrCodeUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l10n.cloudSyncOpenInBrowser),
              ),
            TextButton(
              onPressed: () {
                viewModel.cancelLogin();
                Navigator.pop(context);
              },
              child: Text(l10n.actionCancel),
            ),
          ],
        );
      },
    );
  }
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
      l10n.cloudSyncFailed(cloudSync.error.toString()),
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
    builder: (context) => _CloudBackupListSheet(
      backups: cloudSync.cloudBackups,
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

  await cloudSync.restoreCloudBackup(entry: entry, mode: mode);
  if (!context.mounted) return;
  final error = cloudSync.error;
  ZephyrSnackBar.show(
    context,
    error == null
        ? l10n.cloudSyncRestoreSuccess
        : l10n.cloudSyncFailed(error.toString()),
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
