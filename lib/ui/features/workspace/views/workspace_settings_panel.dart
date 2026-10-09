import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../settings/views/settings_page.dart';

/// Fixed-width settings strip used as a desktop right overlay.
class WorkspaceSettingsPanel extends StatelessWidget {
  const WorkspaceSettingsPanel({
    super.key,
    required this.width,
    required this.onClose,
  });

  static const double preferredWidth = 360;
  static const Duration animationDuration = Duration(milliseconds: 180);

  final double width;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final surface = theme.colorScheme.surface;
    return Material(
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
      color: surface,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: NavigationToolbar(
                middle: Text(
                  l10n.settingsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerMiddle: true,
                trailing: IconButton(
                  onPressed: onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const Expanded(
              child: CompactSettingsList(showStatusBarSettings: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prefetch system fonts used by settings pickers.
void prefetchWorkspaceSettingsFonts(BuildContext context) {
  final scope = ZephyrScope.of(context);
  unawaited(scope.editorPreferences.loadSystemFonts());
  unawaited(scope.theme.loadSystemFonts());
}
