import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/zephyr_controls.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_snackbar.dart';
import '../../settings/views/backup_settings_view.dart';
import '../../settings/view_models/cloud_sync_view_model.dart';

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
                signedIn ? Icons.cloud_outlined : Icons.cloud_off_outlined,
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
    final theme = Theme.of(context);
    // Avoid CheckedPopupMenuItem/ListTile — they ignore height and stay taller.
    const itemHeight = ZephyrControls.menuItemHeight;
    final action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'backup',
          height: itemHeight,
          enabled: !cloudSync.busy,
          child: Text(l10n.cloudSyncBackupNowTitle),
        ),
        PopupMenuItem(
          value: 'restore',
          height: itemHeight,
          enabled: !cloudSync.busy,
          child: Text(l10n.cloudSyncRestoreTitle),
        ),
        PopupMenuItem(
          value: 'auto',
          height: itemHeight,
          enabled: !cloudSync.busy,
          child: Row(
            children: [
              Icon(
                cloudSync.autoSyncEnabled
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.cloudSyncAutoTitle)),
            ],
          ),
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'backup':
        await cloudSync.backupNow();
        if (!context.mounted) return;
        ZephyrSnackBar.show(
          context,
          cloudSync.error == null
              ? l10n.cloudSyncBackupNowSuccess
              : cloudSync.errorMessage(l10n)!,
        );
      case 'restore':
        await showCloudBackupRestoreFlow(context, cloudSync);
      case 'auto':
        await cloudSync.setAutoSyncEnabled(!cloudSync.autoSyncEnabled);
    }
  }
}
