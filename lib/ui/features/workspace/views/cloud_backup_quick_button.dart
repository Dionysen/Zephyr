import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/window_chrome.dart';
import '../../../core/zephyr_controls.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_snackbar.dart';
import '../../settings/views/backup_settings_view.dart';
import '../../settings/view_models/cloud_sync_view_model.dart';
import 'workspace_mobile_tools_drawer.dart';

/// Cloud chrome control: hidden when cloud backup is off; slashed when unbound.
///
/// [hoverBorder] shows only the icon until the pointer is near, then a light
/// border (desktop editor corner). Mobile keeps a normal icon button look.
class CloudBackupQuickButton extends StatefulWidget {
  const CloudBackupQuickButton({
    super.key,
    this.iconSize = 22,
    this.style,
    this.hoverBorder = false,
  });

  final double iconSize;
  final ButtonStyle? style;

  /// When true, idle state is icon-only; hover reveals a rounded border.
  final bool hoverBorder;

  @override
  State<CloudBackupQuickButton> createState() => _CloudBackupQuickButtonState();
}

abstract final class _CloudBackupMenuId {
  static const backup = 'backup';
  static const restore = 'restore';
}

class _CloudBackupQuickButtonState extends State<CloudBackupQuickButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cloudSync = ZephyrScope.of(context).cloudSync;
    return ListenableBuilder(
      listenable: cloudSync,
      builder: (context, _) {
        if (!cloudSync.cloudBackupEnabled) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        final theme = Theme.of(context);
        final signedIn = cloudSync.isSignedIn;
        final busy = cloudSync.isSyncing || cloudSync.isBackingUp;
        final idleAlpha = widget.hoverBorder ? 0.32 : 0.72;
        final iconColor = theme.colorScheme.onSurface.withValues(
          alpha: widget.hoverBorder && _hovered ? 0.78 : idleAlpha,
        );
        final icon = busy
            ? SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(
                signedIn ? Icons.cloud : Icons.cloud_off,
                size: widget.iconSize,
                color: iconColor,
              );

        if (!widget.hoverBorder) {
          return IconButton(
            style: widget.style,
            tooltip: signedIn
                ? l10n.cloudBackupQuickTooltip
                : l10n.cloudBackupQuickTooltipUnconfigured,
            onPressed: cloudSync.busy
                ? null
                : () => unawaited(_onPressed(context, cloudSync)),
            icon: icon,
          );
        }

        final side = widget.iconSize + 10;
        final radius = BorderRadius.circular(8);
        return Tooltip(
          message: signedIn
              ? l10n.cloudBackupQuickTooltip
              : l10n.cloudBackupQuickTooltipUnconfigured,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: _hovered
                      ? theme.colorScheme.outline.withValues(alpha: 0.45)
                      : Colors.transparent,
                ),
              ),
              child: InkWell(
                borderRadius: radius,
                onTap: cloudSync.busy
                    ? null
                    : () => unawaited(_onPressed(context, cloudSync)),
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Center(child: icon),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPressed(
    BuildContext context,
    CloudSyncViewModel cloudSync,
  ) async {
    if (!cloudSync.isSignedIn) {
      await showNutstoreCredentialsDialog(context, cloudSync);
      return;
    }

    if (!WindowChrome.isDesktop) {
      await _openMobileDrawer(context, cloudSync);
      return;
    }
    await _openDesktopMenu(context, cloudSync);
  }

  Future<void> _openMobileDrawer(
    BuildContext context,
    CloudSyncViewModel cloudSync,
  ) async {
    final l10n = context.l10n;
    final themeVm = ZephyrScope.of(context).theme;
    await showWorkspaceMobileToolsDrawer(
      context,
      title: l10n.cloudBackupQuickTooltip,
      order: themeVm.ui.cloudBackupMenuOrder,
      onReorder: themeVm.updateCloudBackupMenuOrder,
      actions: [
        WorkspaceMobileDrawerAction(
          id: _CloudBackupMenuId.backup,
          icon: Icons.cloud_upload,
          label: l10n.cloudSyncBackupNowTitle,
          enabled: !cloudSync.busy,
          onTap: () => unawaited(_runBackup(context, cloudSync)),
        ),
        WorkspaceMobileDrawerAction(
          id: _CloudBackupMenuId.restore,
          icon: Icons.cloud_download,
          label: l10n.cloudSyncRestoreTitle,
          enabled: !cloudSync.busy,
          onTap: () => unawaited(showCloudBackupRestoreFlow(context, cloudSync)),
        ),
      ],
    );
  }

  Future<void> _openDesktopMenu(
    BuildContext context,
    CloudSyncViewModel cloudSync,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final l10n = context.l10n;
    // Avoid CheckedPopupMenuItem/ListTile — they ignore height and stay taller.
    const itemHeight = ZephyrControls.menuItemHeight;
    Widget row({
      required IconData icon,
      required String label,
    }) {
      return Row(
        children: [
          Icon(icon, size: ZephyrControls.iconSize),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      );
    }

    final action = await showMenu<String>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: ZephyrControls.menuMinWidth),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: [
        PopupMenuItem(
          value: _CloudBackupMenuId.backup,
          height: itemHeight,
          enabled: !cloudSync.busy,
          child: row(
            icon: Icons.cloud_upload,
            label: l10n.cloudSyncBackupNowTitle,
          ),
        ),
        PopupMenuItem(
          value: _CloudBackupMenuId.restore,
          height: itemHeight,
          enabled: !cloudSync.busy,
          child: row(
            icon: Icons.cloud_download,
            label: l10n.cloudSyncRestoreTitle,
          ),
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _CloudBackupMenuId.backup:
        await _runBackup(context, cloudSync);
      case _CloudBackupMenuId.restore:
        await showCloudBackupRestoreFlow(context, cloudSync);
    }
  }

  Future<void> _runBackup(
    BuildContext context,
    CloudSyncViewModel cloudSync,
  ) async {
    final l10n = context.l10n;
    await cloudSync.backupNow();
    if (!context.mounted) return;
    ZephyrSnackBar.show(
      context,
      cloudSync.error == null
          ? l10n.cloudSyncBackupNowSuccess
          : cloudSync.errorMessage(l10n)!,
    );
  }
}
