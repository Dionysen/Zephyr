import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_primitives/nested_back_navigator.dart';

import '../../../core/zephyr_floating_chrome.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_theme.dart';
import '../../settings/views/settings_page.dart';

/// Settings panel hosted above the sidebar library dock (desktop).
class WorkspaceSettingsPanel extends StatelessWidget {
  const WorkspaceSettingsPanel({
    super.key,
    required this.onClose,
  });

  /// Minimum panel width (pre–sidebar-dock layout). Grows with a wider dock;
  /// may extend past the sidebar’s right edge.
  static const double preferredWidth = 360;

  static const Duration animationDuration = Duration(milliseconds: 180);

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ZephyrFloatingChrome(
      borderRadius: context.zephyrBarBorderRadius,
      child: NestedBackNavigator(
        onExit: onClose,
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _PanelSettingsHome(onClose: onClose),
          );
        },
      ),
    );
  }
}

class _PanelSettingsHome extends StatelessWidget {
  const _PanelSettingsHome({required this.onClose});

  static const _headerHeight = 52.0;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final surface = theme.colorScheme.surface;
    final topRight = context.zephyrBarBorderRadius.topRight;
    final closeTooltip =
        MaterialLocalizations.of(context).closeButtonTooltip;
    return ColoredBox(
      color: surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    // Match the close square so the title stays visually centered.
                    padding: const EdgeInsets.only(left: _headerHeight),
                    child: Text(
                      l10n.settingsTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: closeTooltip,
                  child: SizedBox(
                    width: _headerHeight,
                    height: _headerHeight,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: onClose,
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(topRight: topRight),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const Expanded(
            child: CompactSettingsList(
              showStatusBarSettings: false,
              showDesktopBehaviorSettings: true,
            ),
          ),
        ],
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

/// Slides the floating settings panel up once when mounted.
class WorkspaceSettingsSlideIn extends StatefulWidget {
  const WorkspaceSettingsSlideIn({super.key, required this.child});

  final Widget child;

  @override
  State<WorkspaceSettingsSlideIn> createState() =>
      _WorkspaceSettingsSlideInState();
}

class _WorkspaceSettingsSlideInState extends State<WorkspaceSettingsSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WorkspaceSettingsPanel.animationDuration,
  )..forward();

  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
        position: _offset,
        child: widget.child,
      );
}
