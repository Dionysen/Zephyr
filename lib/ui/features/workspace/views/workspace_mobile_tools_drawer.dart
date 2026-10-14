import 'package:flutter/material.dart';

import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_theme.dart';

/// One square action in a mobile tools drawer.
class WorkspaceMobileDrawerAction {
  const WorkspaceMobileDrawerAction({
    required this.id,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.selected = false,
  });

  final String id;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final bool selected;
}

/// Bottom drawer of square icon buttons; long-press drag reorders when
/// [onReorder] is set.
Future<void> showWorkspaceMobileToolsDrawer(
  BuildContext context, {
  required String title,
  required List<WorkspaceMobileDrawerAction> actions,
  List<String>? order,
  ValueChanged<List<String>>? onReorder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  if (actions.isEmpty) return Future.value();
  return showZephyrModalSheet<void>(
    context: context,
    builder: (sheetContext) => _WorkspaceMobileToolsDrawer(
      title: title,
      actions: actions,
      order: order,
      onReorder: onReorder,
    ),
  );
}

class _WorkspaceMobileToolsDrawer extends StatefulWidget {
  const _WorkspaceMobileToolsDrawer({
    required this.title,
    required this.actions,
    this.order,
    this.onReorder,
  });

  final String title;
  final List<WorkspaceMobileDrawerAction> actions;
  final List<String>? order;
  final ValueChanged<List<String>>? onReorder;

  @override
  State<_WorkspaceMobileToolsDrawer> createState() =>
      _WorkspaceMobileToolsDrawerState();
}

class _WorkspaceMobileToolsDrawerState
    extends State<_WorkspaceMobileToolsDrawer> {
  static const _columns = 4;
  static const _gap = 10.0;
  static const _padding = EdgeInsets.fromLTRB(16, 0, 16, 20);

  late List<String> _ids;

  @override
  void initState() {
    super.initState();
    _ids = _resolveOrder(widget.actions, widget.order);
  }

  @override
  void didUpdateWidget(covariant _WorkspaceMobileToolsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions != widget.actions || oldWidget.order != widget.order) {
      _ids = _resolveOrder(widget.actions, widget.order);
    }
  }

  static List<String> _resolveOrder(
    List<WorkspaceMobileDrawerAction> actions,
    List<String>? order,
  ) {
    final byId = {for (final action in actions) action.id: action};
    if (order == null || order.isEmpty) {
      return actions.map((action) => action.id).toList(growable: false);
    }
    final ordered = <String>[];
    for (final id in order) {
      if (byId.remove(id) != null) ordered.add(id);
    }
    ordered.addAll(byId.keys);
    return ordered;
  }

  void _reorder(String fromId, String toId) {
    if (fromId == toId || widget.onReorder == null) return;
    final next = List<String>.from(_ids);
    final from = next.indexOf(fromId);
    final to = next.indexOf(toId);
    if (from < 0 || to < 0) return;
    final id = next.removeAt(from);
    next.insert(to, id);
    setState(() => _ids = next);
    widget.onReorder!(List<String>.from(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final byId = {for (final action in widget.actions) action.id: action};
    final items = <WorkspaceMobileDrawerAction>[
      for (final id in _ids)
        if (byId[id] case final action?) action,
    ];
    final canReorder = widget.onReorder != null && items.length > 1;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: _padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: ZephyrBottomSheet.titleStyle(theme)),
              if (canReorder) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.mobileToolsDrawerReorderHint,
                  style: ZephyrBottomSheet.bodyStyle(theme),
                ),
              ],
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = items.length < _columns
                      ? items.length.clamp(1, _columns)
                      : _columns;
                  final tile = (constraints.maxWidth - _gap * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [
                      for (final action in items)
                        SizedBox(
                          width: tile,
                          height: tile,
                          child: _DrawerTile(
                            action: action,
                            canReorder: canReorder,
                            onAccept: (fromId) => _reorder(fromId, action.id),
                            onTap: () {
                              if (!action.enabled) return;
                              Navigator.of(context).pop();
                              action.onTap();
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.action,
    required this.canReorder,
    required this.onAccept,
    required this.onTap,
  });

  final WorkspaceMobileDrawerAction action;
  final bool canReorder;
  final ValueChanged<String> onAccept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    final enabled = action.enabled;
    final foreground = theme.colorScheme.onSurface.withValues(
      alpha: enabled ? (action.selected ? 1 : 0.86) : 0.38,
    );
    final tile = _tileSurface(
      context,
      foreground: foreground,
      radius: radius,
      selected: action.selected,
      onTap: enabled ? onTap : null,
    );

    if (!canReorder) return tile;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          details.data != action.id && enabled,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, _) {
        final highlighted = candidate.isNotEmpty;
        return LongPressDraggable<String>(
          data: action.id,
          maxSimultaneousDrags: enabled ? 1 : 0,
          feedback: Material(
            color: Colors.transparent,
            elevation: 6,
            borderRadius: radius,
            child: SizedBox(
              width: 72,
              height: 72,
              child: _tileSurface(
                context,
                foreground: foreground,
                radius: radius,
                selected: action.selected,
                onTap: null,
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.28, child: tile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: highlighted
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.55),
                      width: 1.5,
                    )
                  : null,
            ),
            child: tile,
          ),
        );
      },
    );
  }

  Widget _tileSurface(
    BuildContext context, {
    required Color foreground,
    required BorderRadius radius,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final fill = selected
        ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.55)
        : theme.colorScheme.surfaceContainerHigh;
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    action.icon ?? Icons.circle_outlined,
                    size: 26,
                    color: foreground,
                  ),
                ),
              ),
              Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  height: 1.15,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
