import 'package:flutter/material.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../core/breakpoints.dart';
import '../../../core/zephyr_l10n.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../editor/views/article_history_sheet.dart';

class SidebarMenuAction {
  const SidebarMenuAction({
    required this.id,
    required this.label,
    required this.icon,
    this.isDestructive = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

Future<String?> showSidebarLibraryMenu(
  BuildContext context, {
  required List<SidebarMenuAction> actions,
  RelativeRect? position,
}) async {
  if (actions.isEmpty) return null;
  final compact = ZephyrBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
  if (compact) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                _CompactSheetTile(
                  icon: action.icon,
                  label: action.label,
                  iconColor: action.isDestructive
                      ? theme.colorScheme.error
                      : null,
                  labelColor: action.isDestructive
                      ? theme.colorScheme.error
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(action.id),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final rect =
      position ??
      RelativeRect.fromRect(
        Offset.zero & const Size(1, 1),
        Offset.zero & overlay.size,
      );
  return showMenu<String>(
    context: context,
    position: rect,
    items: [
      for (final action in actions)
        PopupMenuItem<String>(
          value: action.id,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              action.icon,
              color: action.isDestructive
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            title: Text(
              action.label,
              style: action.isDestructive
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
          ),
        ),
    ],
  );
}

RelativeRect secondaryMenuPosition(
  BuildContext context,
  TapDownDetails details,
) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final point = details.globalPosition;
  return RelativeRect.fromRect(
    Rect.fromLTWH(point.dx, point.dy, 0, 0),
    Offset.zero & overlay.size,
  );
}

List<SidebarMenuAction> volumeMenuActions(AppLocalizations l10n) => [
  SidebarMenuAction(
    id: 'insert',
    label: l10n.volumeInsertBelow,
    icon: Icons.create_new_folder_outlined,
  ),
  SidebarMenuAction(
    id: 'rename',
    label: l10n.actionRename,
    icon: Icons.drive_file_rename_outline,
  ),
  SidebarMenuAction(
    id: 'delete',
    label: l10n.actionDelete,
    icon: Icons.delete_outline,
    isDestructive: true,
  ),
];

List<SidebarMenuAction> chapterMenuActions(AppLocalizations l10n) => [
  SidebarMenuAction(
    id: 'insert',
    label: l10n.chapterInsertBelow,
    icon: Icons.note_add_outlined,
  ),
  SidebarMenuAction(
    id: 'rename',
    label: l10n.actionRename,
    icon: Icons.drive_file_rename_outline,
  ),
  SidebarMenuAction(
    id: 'history',
    label: l10n.historyMenuLabel,
    icon: Icons.history,
  ),
  SidebarMenuAction(
    id: 'move',
    label: l10n.actionMoveToVolume,
    icon: Icons.drive_file_move_outline,
  ),
  SidebarMenuAction(
    id: 'delete',
    label: l10n.actionDelete,
    icon: Icons.delete_outline,
    isDestructive: true,
  ),
];

Future<void> handleVolumeMenuAction(
  BuildContext context, {
  required LibraryViewModel model,
  required WritingCategory volume,
  required String actionId,
}) async {
  final l10n = context.l10n;
  switch (actionId) {
    case 'insert':
      await model.insertVolumeBelow(volume.id);
    case 'rename':
      final name = await showRenameDialog(
        context,
        title: l10n.renameVolumeTitle,
        label: l10n.volumeNameLabel,
        initialValue: volume.name,
      );
      if (name != null) {
        await model.renameVolume(volumeId: volume.id, name: name);
      }
    case 'delete':
      final choice = await showDeleteVolumeDialog(
        context,
        volumeName: volume.name,
      );
      if (choice == null) return;
      await model.deleteVolume(
        volumeId: volume.id,
        deleteArticles: choice,
      );
  }
}

Future<void> handleChapterMenuAction(
  BuildContext context, {
  required LibraryViewModel model,
  required ArticleSummary chapter,
  required String actionId,
}) async {
  final l10n = context.l10n;
  switch (actionId) {
    case 'insert':
      await model.insertChapterBelow(chapter.id);
    case 'rename':
      final title = await showRenameDialog(
        context,
        title: l10n.renameChapterTitle,
        label: l10n.chapterNameLabel,
        initialValue: chapter.title,
      );
      if (title != null) {
        await model.renameChapter(articleId: chapter.id, title: title);
      }
    case 'history':
      await showArticleHistorySheet(
        context,
        model: model,
        articleId: chapter.id,
      );
    case 'move':
      final volumes =
          model.library?.categories
              .where((item) => item.folderId == chapter.folderId)
              .toList(growable: false) ??
          const [];
      final target = await showMoveChapterSheet(
        context,
        volumes: volumes,
        currentCategoryId: chapter.categoryId,
      );
      if (target == null) return;
      await model.moveChapterToVolume(
        articleId: chapter.id,
        volumeId: target.isEmpty ? null : target,
      );
    case 'delete':
      final confirmed = await showDeleteChapterDialog(
        context,
        chapterTitle: chapter.title,
      );
      if (confirmed != true) return;
      await model.deleteChapter(chapter.id);
  }
}

Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(
      title: title,
      label: label,
      initialValue: initialValue,
    ),
  );
}

Future<bool?> showDeleteChapterDialog(
  BuildContext context, {
  required String chapterTitle,
}) {
  final l10n = context.l10n;
  final name = chapterTitle.trim().isEmpty
      ? l10n.untitled
      : chapterTitle.trim();
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(l10n.deleteChapterTitle),
        content: Text(l10n.deleteChapterBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      );
    },
  );
}

/// Returns `true` when chapters should also be deleted, `false` for volume-only.
Future<bool?> showDeleteVolumeDialog(
  BuildContext context, {
  required String volumeName,
}) {
  final l10n = context.l10n;
  final name = volumeName.trim().isEmpty
      ? l10n.untitled
      : volumeName.trim();
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text(l10n.deleteVolumeTitle),
        content: Text(l10n.deleteVolumeBody(name)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.deleteVolumeOnly),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteVolumeAndChapters),
          ),
        ],
      );
    },
  );
}

/// Empty string means unfiled; null means cancelled.
Future<String?> showMoveChapterSheet(
  BuildContext context, {
  required List<WritingCategory> volumes,
  String? currentCategoryId,
}) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                l10n.moveToVolumeSheetTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            _CompactSheetTile(
              icon: Icons.inbox_outlined,
              label: l10n.unfiledVolume,
              selected: currentCategoryId == null,
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
            for (final volume in volumes)
              _CompactSheetTile(
                icon: Icons.folder_outlined,
                label: volume.name,
                selected: volume.id == currentCategoryId,
                onTap: () => Navigator.of(sheetContext).pop(volume.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Shared compact row for sidebar bottom sheets (menus + move-to-volume).
class _CompactSheetTile extends StatelessWidget {
  const _CompactSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.selected = false,
  });

  static const double _height = 44;
  static const double _iconSize = 20;
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 20);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? theme.colorScheme.primary : null;
    return SizedBox(
      height: _height,
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: _padding,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: _iconSize,
                  color: iconColor ?? foreground,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: labelColor ?? foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({
    required this.title,
    required this.label,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String initialValue;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.label),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationNameRequired;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}
