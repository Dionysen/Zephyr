import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../core/breakpoints.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_controls.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_resize_handle.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/view_models/library_view_model.dart';
import 'workspace_sidebar_library_actions.dart';

enum SidebarMode { docked, drawer }

class WorkspaceSidebar extends StatefulWidget {
  const WorkspaceSidebar({
    super.key,
    required this.model,
    required this.mode,
    required this.openLibrary,
    required this.openSettings,
  });

  final LibraryViewModel model;
  final SidebarMode mode;
  final Future<void> Function() openLibrary;
  final VoidCallback openSettings;

  @override
  State<WorkspaceSidebar> createState() => _WorkspaceSidebarState();
}

class _WorkspaceSidebarState extends State<WorkspaceSidebar> {
  final _chapterTreeKey = GlobalKey<_ChapterTreeState>();

  LibraryViewModel get model => widget.model;
  bool get _canCreateVolume =>
      !model.isReadOnly && model.selectedBook?.isTrash != true;
  bool get _canReorder => _canCreateVolume;

  @override
  Widget build(BuildContext context) {
    final drawer = widget.mode == SidebarMode.drawer;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Column(
          children: [
            if (drawer)
              _DrawerSidebarHeader(
                model: model,
                onToggleAllVolumes: model.hasVolumes
                    ? () => _chapterTreeKey.currentState?.toggleAllVolumes()
                    : null,
                canReorder: _canReorder,
              )
            else ...[
              SizedBox(
                height: WorkspaceHeader.height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (WindowChrome.leadingChromeInset > 0)
                      SizedBox(width: WindowChrome.leadingChromeInset),
                    IconButton(
                      onPressed: model.toggleSidebar,
                      icon: const Icon(Icons.menu_open),
                      tooltip: 'Hide sidebar',
                    ),
                    const Expanded(
                      child: WindowDragArea(child: SizedBox.expand()),
                    ),
                    IconButton(
                      onPressed: _canCreateVolume ? model.createVolume : null,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      tooltip: 'New volume',
                    ),
                    _ReorderModeButton(
                      enabled: _canReorder,
                      active: model.isReorderMode,
                      onPressed: model.toggleReorderMode,
                    ),
                  ],
                ),
              ),
              WorkspaceBookPicker(model: model, library: model.library!),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: model.hasVolumes
                          ? () =>
                                _chapterTreeKey.currentState?.toggleAllVolumes()
                          : null,
                      icon: Icon(
                        model.areAllVolumesExpanded
                            ? Icons.unfold_less
                            : Icons.unfold_more,
                      ),
                      tooltip: model.areAllVolumesExpanded
                          ? 'Collapse all'
                          : 'Expand all',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed:
                          model.isReadOnly ||
                              model.selectedBook?.isTrash == true
                          ? null
                          : model.createArticle,
                      icon: const Icon(Icons.note_add_outlined),
                      tooltip: 'New chapter',
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: _ChapterTree(
                key: _chapterTreeKey,
                model: model,
                library: model.library!,
              ),
            ),
            _LibraryDock(
              model: model,
              openLibrary: widget.openLibrary,
              openSettings: widget.openSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile drawer header: book name + chapter count on the left, tools on the right.
class _ReorderModeButton extends StatelessWidget {
  const _ReorderModeButton({
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final bool enabled;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: enabled ? onPressed : null,
      isSelected: active,
      icon: const Icon(Icons.swap_vert),
      selectedIcon: Icon(
        Icons.swap_vert,
        color: theme.colorScheme.primary,
      ),
      tooltip: active ? 'Done reordering' : 'Reorder',
    );
  }
}

class _DrawerSidebarHeader extends StatelessWidget {
  const _DrawerSidebarHeader({
    required this.model,
    required this.onToggleAllVolumes,
    required this.canReorder,
  });

  final LibraryViewModel model;
  final VoidCallback? onToggleAllVolumes;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = model.selectedBook;
    final stats = book == null ? null : model.bookStats(book.id);
    final meta = stats == null
        ? null
        : '${stats.volumes}卷 ${stats.chapters}章';
    final isTrash = book?.isTrash == true;
    final titleColor = isTrash ? theme.colorScheme.error : null;
    final metaColor = isTrash
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 6),
      child: Row(
        children: [
          if (isTrash) ...[
            Icon(
              Icons.delete_outline,
              size: ZephyrControls.iconSize,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book?.name ?? 'Select a book',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                  ),
                ),
                if (meta != null)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: metaColor,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleAllVolumes,
            icon: Icon(
              model.areAllVolumesExpanded
                  ? Icons.unfold_less
                  : Icons.unfold_more,
            ),
            tooltip: model.areAllVolumesExpanded
                ? 'Collapse all'
                : 'Expand all',
          ),
          IconButton(
            onPressed: model.isReadOnly || isTrash ? null : model.createVolume,
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New volume',
          ),
          IconButton(
            onPressed: model.isReadOnly || isTrash ? null : model.createArticle,
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'New chapter',
          ),
          _ReorderModeButton(
            enabled: canReorder,
            active: model.isReorderMode,
            onPressed: model.toggleReorderMode,
          ),
        ],
      ),
    );
  }
}

/// One overflow action for the mobile editor “more” sheet.
///
/// Pass tools via [WorkspaceMobileBookBar.tools] (or [toolsBuilder]) so future
/// settings/actions can plug in without changing the bar layout.
class WorkspaceMobileTool {
  const WorkspaceMobileTool({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
}

/// Floating chrome for the compact editor surface.
class WorkspaceMobileBookBar extends StatelessWidget {
  const WorkspaceMobileBookBar({
    super.key,
    required this.model,
    required this.onOpenMenu,
    this.tools = const [],
    this.toolsBuilder,
  });

  /// Compact floating bar; icon buttons sit at 40 inside a 48-tall shell.
  static const height = 48.0;
  static const _iconButtonSize = 40.0;
  static const _iconSize = 22.0;

  final LibraryViewModel model;
  final VoidCallback onOpenMenu;

  /// Static tools shown in the overflow sheet.
  final List<WorkspaceMobileTool> tools;

  /// Optional builder merged after [tools] when the sheet opens.
  final List<WorkspaceMobileTool> Function(BuildContext context)? toolsBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final library = model.library;
    if (library == null) return const SizedBox.shrink();
    final radius = context.zephyrBorderRadius;
    final book = model.selectedBook;
    final isTrash = book?.isTrash == true;
    final bookName = book?.name ?? '选择书籍';
    final surface = theme.colorScheme.surface;
    final shadow = theme.colorScheme.shadow;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: 0.14),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: shadow.withValues(alpha: 0.08),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: shadow.withValues(alpha: 0.05),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  style: _mobileBarIconStyle(context),
                  onPressed: onOpenMenu,
                  icon: const Icon(Icons.menu, size: _iconSize),
                  tooltip: 'Open library',
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _showBookSheet(context, library: library),
                    style: TextButton.styleFrom(
                      foregroundColor: isTrash
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, _iconButtonSize),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        if (isTrash) ...[
                          Icon(
                            Icons.delete_outline,
                            size: _iconSize,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            bookName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: isTrash ? theme.colorScheme.error : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  style: _mobileBarIconStyle(context),
                  onPressed: () => _showToolsSheet(context),
                  icon: const Icon(Icons.more_vert, size: _iconSize),
                  tooltip: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _mobileBarIconStyle(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.76),
      iconSize: _iconSize,
      padding: const EdgeInsets.all(9),
      minimumSize: const Size(_iconButtonSize, _iconButtonSize),
      fixedSize: const Size(_iconButtonSize, _iconButtonSize),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: context.zephyrShape.iconButtonShape,
    );
  }

  Future<void> _showBookSheet(
    BuildContext context, {
    required WritingLibrary library,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _MobileBookSheet(
        hostContext: context,
        model: model,
        library: library,
      ),
    );
  }

  Future<void> _showToolsSheet(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final built = toolsBuilder?.call(context) ?? const <WorkspaceMobileTool>[];
    await showWorkspaceMobileToolsSheet(
      context,
      tools: [...tools, ...built],
    );
  }
}

/// Opens the reserved mobile overflow sheet (tools / settings).
Future<void> showWorkspaceMobileToolsSheet(
  BuildContext context, {
  List<WorkspaceMobileTool> tools = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _MobileToolsSheet(tools: tools),
  );
}

class _MobileBookSheet extends StatelessWidget {
  const _MobileBookSheet({
    required this.hostContext,
    required this.model,
    required this.library,
  });

  final BuildContext hostContext;
  final LibraryViewModel model;
  final WritingLibrary library;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final books = library.folders;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text('选择书籍', style: theme.textTheme.titleMedium),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  final selected = book.id == model.selectedBook?.id;
                  final isTrash = book.isTrash;
                  final stats = model.bookStats(book.id);
                  final subtitle = _mobileBookSubtitle(book) ??
                      '${stats.volumes}卷 ${stats.chapters}章';
                  final accent = isTrash ? theme.colorScheme.error : null;

                  return ListTile(
                    selected: selected,
                    leading: Icon(
                      isTrash ? Icons.delete_outline : Icons.book_outlined,
                      color: accent,
                    ),
                    title: Text(
                      book.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: accent),
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: accent == null
                          ? null
                          : TextStyle(color: accent.withValues(alpha: 0.8)),
                    ),
                    trailing: isTrash
                        ? null
                        : IconButton(
                            tooltip: '编辑书籍',
                            onPressed: model.isReadOnly
                                ? null
                                : () async {
                                    Navigator.of(context).pop();
                                    if (!hostContext.mounted) return;
                                    await _editBook(
                                      hostContext,
                                      model: model,
                                      book: book,
                                    );
                                  },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await model.selectBook(book.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _mobileBookSubtitle(WritingFolder book) {
    final tags = book.tags.trim();
    if (tags.isNotEmpty) {
      return tags.split(RegExp(r'[,;，；]')).first.trim();
    }
    final description = book.description.trim();
    if (description.isEmpty) return null;
    return description;
  }
}

class _MobileToolsSheet extends StatelessWidget {
  const _MobileToolsSheet({required this.tools});

  final List<WorkspaceMobileTool> tools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('更多', style: theme.textTheme.titleMedium),
          ),
          if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Text(
                '暂无可用工具',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final tool in tools)
              ListTile(
                enabled: tool.enabled,
                leading: tool.icon == null ? null : Icon(tool.icon),
                title: Text(tool.label),
                onTap: !tool.enabled
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        tool.onTap();
                      },
              ),
        ],
      ),
    );
  }
}

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.model,
    this.showMenuButton = false,
    this.showSidebarToggle = false,
    this.onOpenMenu,
  });

  static double get height => WindowChrome.titleBarHeight;

  final LibraryViewModel model;
  final bool showMenuButton;
  final bool showSidebarToggle;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = model.article?.title.trim();
    final leadingInset = showSidebarToggle
        ? WindowChrome.leadingChromeInset
        : 0.0;
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Row(
              children: [
                if (leadingInset > 0)
                  WindowDragArea(
                    child: SizedBox(width: leadingInset, height: height),
                  ),
                if (showMenuButton)
                  IconButton(
                    onPressed: onOpenMenu ??
                        () => Scaffold.maybeOf(context)?.openDrawer(),
                    icon: const Icon(Icons.menu),
                    tooltip: 'Open library',
                  ),
                if (showSidebarToggle)
                  IconButton(
                    onPressed: model.toggleSidebar,
                    icon: const Icon(Icons.menu_open),
                    tooltip: 'Open sidebar',
                  ),
                const Expanded(child: WindowDragArea(child: SizedBox.expand())),
                const WindowCaptionButtons(),
              ],
            ),
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showMenuButton || showSidebarToggle ? 48 : 16,
                  ),
                  child: Text(
                    title?.isNotEmpty == true ? title! : 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceBookPicker extends StatelessWidget {
  const WorkspaceBookPicker({
    super.key,
    required this.model,
    required this.library,
    this.dense = false,
  });

  final LibraryViewModel model;
  final WritingLibrary library;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hostContext = context;
    final books = library.folders;
    final bookById = {for (final book in books) book.id: book};
    return Padding(
      padding: dense
          ? const EdgeInsets.fromLTRB(0, 0, 8, 0)
          : const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: ZephyrDropdown<String>(
        value: model.selectedBook?.id,
        hint: 'Select a book',
        items: [
          for (final book in books)
            ZephyrDropdownItem(
              value: book.id,
              label: book.name,
              subtitle: _bookSubtitle(book),
            ),
        ],
        onChanged: model.selectBook,
        triggerBuilder: (context, {required selected, required isOpen}) {
          final book = selected == null ? null : bookById[selected.value];
          final stats = book == null ? null : model.bookStats(book.id);
          final meta = stats == null
              ? null
              : '${stats.volumes}卷 ${stats.chapters}章';
          final theme = Theme.of(context);
          final isTrash = book?.isTrash == true;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 10),
            child: Row(
              children: [
                if (isTrash) ...[
                  Icon(
                    Icons.delete_outline,
                    size: ZephyrControls.iconSize,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selected?.label ?? 'Select a book',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isTrash ? theme.colorScheme.error : null,
                    ),
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    meta,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isTrash
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  size: ZephyrControls.iconSize,
                ),
              ],
            ),
          );
        },
        itemBuilder:
            (
              context, {
              required item,
              required selected,
              required highlighted,
              required onSelect,
              required onDismiss,
            }) {
              final book = bookById[item.value];
              final subtitle = item.subtitle;
              final theme = Theme.of(context);
              final isTrash = book?.isTrash == true;
              final trashColor = theme.colorScheme.error;
              return Stack(
                fit: StackFit.expand,
                children: [
                  InkWell(
                    onTap: onSelect,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: ZephyrControls.buttonSize + 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTrash
                                ? Icons.delete_outline
                                : Icons.book_outlined,
                            size: ZephyrControls.iconSize,
                            color: isTrash ? trashColor : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isTrash ? trashColor : null,
                              ),
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 96),
                              child: Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isTrash
                                      ? trashColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!isTrash)
                    Positioned(
                      top:
                          (ZephyrControls.fieldHeight -
                              ZephyrControls.buttonSize) /
                          2,
                      right: 4,
                      width: ZephyrControls.buttonSize,
                      height: ZephyrControls.buttonSize,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          customBorder: hostContext.zephyrShape.iconButtonShape,
                          onTap: model.isReadOnly || book == null
                              ? null
                              : () {
                                  final editing = book;
                                  onDismiss();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (!hostContext.mounted) {
                                      return;
                                    }
                                    unawaited(
                                      _editBook(
                                        hostContext,
                                        model: model,
                                        book: editing,
                                      ),
                                    );
                                  });
                                },
                          child: Icon(
                            Icons.edit_outlined,
                            size: ZephyrControls.iconSize,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }

  String? _bookSubtitle(WritingFolder book) {
    final tags = book.tags.trim();
    if (tags.isNotEmpty) {
      return tags.split(RegExp(r'[,;，；]')).first.trim();
    }
    final description = book.description.trim();
    if (description.isEmpty) return null;
    return description;
  }
}

Future<void> _editBook(
  BuildContext context, {
  required LibraryViewModel model,
  required WritingFolder book,
}) async {
  final result = await showDialog<_BookEditResult>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _EditBookDialog(book: book),
  );
  if (result == null) return;
  await model.updateBook(
    folderId: book.id,
    name: result.name,
    description: result.description,
    tags: result.tags,
  );
}

class _BookEditResult {
  const _BookEditResult({
    required this.name,
    required this.description,
    required this.tags,
  });
  final String name;
  final String description;
  final String tags;
}

class _EditBookDialog extends StatefulWidget {
  const _EditBookDialog({required this.book});

  final WritingFolder book;

  @override
  State<_EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<_EditBookDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.book.name);
    _description = TextEditingController(text: widget.book.description);
    _tags = TextEditingController(text: widget.book.tags);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _BookEditResult(
        name: _name.text.trim(),
        description: _description.text.trim(),
        tags: _tags.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('编辑书籍', style: theme.textTheme.titleLarge),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '书名',
                  hintText: '输入书名',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入书名';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: '标签',
                  hintText: '例如：文学',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: '简介',
                  hintText: '简要说明这本书',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

class _ChapterTree extends StatefulWidget {
  const _ChapterTree({
    super.key,
    required this.model,
    required this.library,
  });

  final LibraryViewModel model;
  final WritingLibrary library;

  @override
  State<_ChapterTree> createState() => _ChapterTreeState();
}

class _ChapterTreeState extends State<_ChapterTree> {
  final _scrollController = ScrollController();
  final _volumeKeys = <String, GlobalKey>{};
  String? _restoredBookId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant _ChapterTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.library, oldWidget.library)) {
      _restoredBookId = null;
    }
    final bookId = widget.model.selectedBook?.id;
    if (bookId != _restoredBookId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    widget.model.updateSidebarScrollOffset(_scrollController.offset);
  }

  void _restoreScrollIfNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    final bookId = widget.model.selectedBook?.id;
    if (bookId == null || _restoredBookId == bookId) return;
    final offset = widget.model.sidebarScrollOffset;
    final max = _scrollController.position.maxScrollExtent;
    if (offset > 0 && max == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final bookStill = widget.model.selectedBook?.id;
        if (bookStill != bookId) return;
        final max2 = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(offset.clamp(0.0, max2));
        _restoredBookId = bookId;
      });
      return;
    }
    _scrollController.jumpTo(offset.clamp(0.0, max));
    _restoredBookId = bookId;
  }

  GlobalKey _volumeKeyFor(String volumeId) =>
      _volumeKeys.putIfAbsent(volumeId, GlobalKey.new);

  RenderSliver? _volumeSliver(String volumeId) {
    final renderObject = _volumeKeyFor(
      volumeId,
    ).currentContext?.findRenderObject();
    return renderObject is RenderSliver ? renderObject : null;
  }

  /// Offset that puts the collapsing volume at the viewport top.
  ///
  /// Single-volume: [SliverConstraints.precedingScrollExtent].
  /// Collapse-all: also subtract chapter bodies of fully scrolled-past volumes
  /// above the active one (they shrink to headers).
  double? _collapseTargetOffset({String? volumeId}) {
    final ids = _volumeKeys.keys.toList(growable: false);
    final String? activeId;
    if (volumeId != null) {
      activeId = volumeId;
    } else {
      String? found;
      for (final id in ids) {
        final sliver = _volumeSliver(id);
        if (sliver == null) continue;
        final painted = sliver.geometry?.paintExtent ?? 0;
        if (sliver.constraints.scrollOffset > 0 && painted > 0) {
          found = id;
          break;
        }
      }
      activeId = found;
    }
    if (activeId == null) return null;

    final active = _volumeSliver(activeId);
    if (active == null || active.constraints.scrollOffset <= 0) return null;

    var target = active.constraints.precedingScrollExtent;
    if (volumeId != null) return target;

    for (final id in ids) {
      if (id == activeId) break;
      final sliver = _volumeSliver(id);
      if (sliver == null) continue;
      final painted = sliver.geometry?.paintExtent ?? 0;
      if (painted > 0) continue;
      final extent = sliver.geometry?.scrollExtent ?? 0;
      final headerExtent = _headerExtentOf(sliver);
      final body = (extent - headerExtent).clamp(0.0, extent);
      target -= body;
    }
    return target;
  }

  double _headerExtentOf(RenderSliver group) {
    if (group is! RenderSliverMainAxisGroup) return 0;
    return group.firstChild?.geometry?.scrollExtent ?? 0;
  }

  void _jumpToAfterLayout(double target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(target.clamp(0.0, max));
    });
  }

  void _toggleVolume(String volumeId) {
    final collapsing = widget.model.isVolumeExpanded(volumeId);
    final target = collapsing ? _collapseTargetOffset(volumeId: volumeId) : null;
    widget.model.toggleVolume(volumeId);
    if (target != null) _jumpToAfterLayout(target);
  }

  void toggleAllVolumes() {
    final collapsing = widget.model.areAllVolumesExpanded;
    final target = collapsing ? _collapseTargetOffset() : null;
    widget.model.toggleAllVolumes();
    if (target != null) _jumpToAfterLayout(target);
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final library = widget.library;
    final bookId = model.selectedBook?.id;
    if (bookId == null) return const SizedBox();
    final chapters = library.articles
        .where((item) => item.folderId == bookId)
        .toList(growable: false);
    final isTrash = bookId == WritingFolder.trashId;
    final canManage = !model.isReadOnly && !isTrash;
    final showDragHandles = canManage && model.isReorderMode;
    final pinnedBackground = Theme.of(
      context,
    ).colorScheme.surfaceContainerLowest;
    final volumes = library.categories
        .where((item) => !isTrash && item.folderId == bookId)
        .toList(growable: false);
    final volumeIds = volumes.map((item) => item.id).toList(growable: false);
    final slivers = <Widget>[
      const SliverToBoxAdapter(child: SizedBox(height: 2)),
    ];
    for (var volumeIndex = 0; volumeIndex < volumes.length; volumeIndex++) {
      final volume = volumes[volumeIndex];
      final volumeChapters = chapters
          .where((item) => item.categoryId == volume.id)
          .toList(growable: false);
      final chapterIds =
          volumeChapters.map((item) => item.id).toList(growable: false);
      final header = _VolumeRow(
        volume: volume,
        model: model,
        chapterCount: volumeChapters.length,
        siblingIds: volumeIds,
        canManage: canManage,
        showDragHandle: showDragHandles,
        isLast: volumeIndex == volumes.length - 1,
        onToggle: () => _toggleVolume(volume.id),
      );
      // Keep a stable SliverMainAxisGroup so collapsing during a volume drag
      // does not dispose the active Draggable.
      slivers.add(
        SliverMainAxisGroup(
          key: _volumeKeyFor(volume.id),
          slivers: [
            PinnedHeaderSliver(
              child: ColoredBox(
                color: pinnedBackground,
                child: header,
              ),
            ),
            if (model.isVolumeExpanded(volume.id) && volumeChapters.isNotEmpty)
              SliverList.builder(
                itemCount: volumeChapters.length,
                itemBuilder: (context, index) => _ChapterRow(
                  chapter: volumeChapters[index],
                  model: model,
                  siblingIds: chapterIds,
                  canManage: canManage,
                  showDragHandle: showDragHandles,
                  isLast: index == volumeChapters.length - 1,
                ),
              ),
          ],
        ),
      );
    }
    final loose = chapters
        .where((item) => isTrash || item.categoryId == null)
        .toList(growable: false);
    if (loose.isNotEmpty) {
      if (!isTrash) {
        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: Text('Unfiled chapters'),
            ),
          ),
        );
      }
      final looseIds = loose.map((item) => item.id).toList(growable: false);
      slivers.add(
        SliverList.builder(
          itemCount: loose.length,
          itemBuilder: (context, index) => _ChapterRow(
            chapter: loose[index],
            model: model,
            siblingIds: looseIds,
            canManage: canManage,
            showDragHandle: showDragHandles,
            isLast: index == loose.length - 1,
          ),
        ),
      );
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
    return CustomScrollView(controller: _scrollController, slivers: slivers);
  }
}

class _VolumeDragData {
  const _VolumeDragData(this.volumeId);
  final String volumeId;
}

class _ChapterDragData {
  const _ChapterDragData({required this.articleId, required this.categoryId});
  final String articleId;
  final String? categoryId;
}

/// Moves [draggedId] before/after [targetId] within a sibling id list.
List<String>? _reorderSiblingIds({
  required List<String> siblingIds,
  required String draggedId,
  required String targetId,
  required bool insertAfter,
}) {
  if (draggedId == targetId) return null;
  final ids = List<String>.from(siblingIds);
  final from = ids.indexOf(draggedId);
  var to = ids.indexOf(targetId);
  if (from < 0 || to < 0) return null;
  final item = ids.removeAt(from);
  if (from < to) to -= 1;
  if (insertAfter) to += 1;
  ids.insert(to.clamp(0, ids.length), item);
  return ids;
}

/// Gap above a row: one drop slot with the preview line centered in the margin.
class _ReorderBeforeSlot<T extends Object> extends StatelessWidget {
  const _ReorderBeforeSlot({
    required this.enabled,
    required this.gap,
    required this.horizontalInset,
    required this.canAccept,
    required this.onAccept,
    required this.child,
  });

  final bool enabled;
  final double gap;
  final double horizontalInset;
  final bool Function(T data) canAccept;
  final void Function(T data) onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Padding(
        padding: EdgeInsets.only(top: gap),
        child: child,
      );
    }
    final theme = Theme.of(context);
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: gap,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    height: 2,
                    color: highlight
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

/// Trailing gap under the last row for "insert after last".
class _ReorderAfterGap<T extends Object> extends StatelessWidget {
  const _ReorderAfterGap({
    required this.enabled,
    required this.gap,
    required this.horizontalInset,
    required this.canAccept,
    required this.onAccept,
  });

  final bool enabled;
  final double gap;
  final double horizontalInset;
  final bool Function(T data) canAccept;
  final void Function(T data) onAccept;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return SizedBox(
          height: gap,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                height: 2,
                color: highlight
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.volume,
    required this.model,
    required this.chapterCount,
    required this.siblingIds,
    required this.canManage,
    required this.showDragHandle,
    required this.isLast,
    required this.onToggle,
  });

  static const _volumeGap = 8.0;

  final WritingCategory volume;
  final LibraryViewModel model;
  final int chapterCount;
  final List<String> siblingIds;
  final bool canManage;
  final bool showDragHandle;
  final bool isLast;
  final VoidCallback onToggle;

  Future<void> _openMenu(
    BuildContext context, {
    RelativeRect? position,
  }) async {
    if (!canManage) return;
    final actionId = await showSidebarLibraryMenu(
      context,
      actions: volumeMenuActions,
      position: position,
    );
    if (actionId == null || !context.mounted) return;
    await handleVolumeMenuAction(
      context,
      model: model,
      volume: volume,
      actionId: actionId,
    );
  }

  Future<void> _acceptVolumeDrop(
    _VolumeDragData data, {
    required bool insertAfter,
  }) async {
    if (!showDragHandle) return;
    final ids = _reorderSiblingIds(
      siblingIds: siblingIds,
      draggedId: data.volumeId,
      targetId: volume.id,
      insertAfter: insertAfter,
    );
    if (ids == null) return;
    await model.reorderVolumes(ids);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    final listInset = context.zephyrSidebarItemInset;
    final compact = ZephyrBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: listInset),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: context.zephyrOutlineSide(),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onToggle,
          onLongPress: compact && !showDragHandle
              ? () => _openMenu(context)
              : null,
          onSecondaryTapDown: !compact
              ? (details) => _openMenu(
                    context,
                    position: secondaryMenuPosition(context, details),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  model.isVolumeExpanded(volume.id)
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(volume.name, style: theme.textTheme.titleSmall),
                ),
                Text(
                  '$chapterCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (showDragHandle) ...[
                  const SizedBox(width: 4),
                  _SidebarDragHandle<_VolumeDragData>(
                    data: _VolumeDragData(volume.id),
                    feedbackLabel: volume.name,
                    onDragStarted: model.beginVolumeReorderDrag,
                    onDragEnded: model.endVolumeReorderDrag,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReorderBeforeSlot<_VolumeDragData>(
          enabled: showDragHandle,
          gap: showDragHandle ? _volumeGap : 6,
          horizontalInset: listInset,
          canAccept: (data) => data.volumeId != volume.id,
          onAccept: (data) => _acceptVolumeDrop(data, insertAfter: false),
          child: body,
        ),
        _ReorderAfterGap<_VolumeDragData>(
          enabled: showDragHandle && isLast,
          gap: _volumeGap,
          horizontalInset: listInset,
          canAccept: (data) => data.volumeId != volume.id,
          onAccept: (data) => _acceptVolumeDrop(data, insertAfter: true),
        ),
      ],
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.model,
    required this.siblingIds,
    required this.canManage,
    required this.showDragHandle,
    required this.isLast,
  });

  static const _chapterGap = 8.0;
  static const _chapterGapIdle = 2.0;
  static const _lineGap = 2.0;
  static const _previewDateGap = 4.0;
  static const _textHeight = 1.15;

  final ArticleSummary chapter;
  final LibraryViewModel model;
  final List<String> siblingIds;
  final bool canManage;
  final bool showDragHandle;
  final bool isLast;

  Future<void> _openMenu(
    BuildContext context, {
    RelativeRect? position,
  }) async {
    if (!canManage) return;
    final actionId = await showSidebarLibraryMenu(
      context,
      actions: chapterMenuActions,
      position: position,
    );
    if (actionId == null || !context.mounted) return;
    await handleChapterMenuAction(
      context,
      model: model,
      chapter: chapter,
      actionId: actionId,
    );
  }

  Future<void> _acceptChapterDrop(
    _ChapterDragData data, {
    required bool insertAfter,
  }) async {
    if (!showDragHandle || data.categoryId != chapter.categoryId) return;
    final ids = _reorderSiblingIds(
      siblingIds: siblingIds,
      draggedId: data.articleId,
      targetId: chapter.id,
      insertAfter: insertAfter,
    );
    if (ids == null) return;
    await model.reorderChapters(
      volumeId: chapter.categoryId,
      orderedIds: ids,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    final compact = ZephyrBreakpoints.isCompact(MediaQuery.sizeOf(context).width);
    final activeArticle = model.article?.id == chapter.id ? model.article : null;
    final selected = activeArticle != null;
    final metaText =
        '创建于${_formatDate(chapter.createdAt)} - 修改于${_formatDate(activeArticle?.updatedAt ?? chapter.updatedAt)} - ${activeArticle?.wordCount ?? chapter.wordCount}字';
    final preview = chapter.summary
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll('\u3000', '')
        .trim();
    final title = chapter.title.isEmpty ? 'Untitled' : chapter.title;
    final listInset = context.zephyrSidebarItemInset;
    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: listInset),
      child: Material(
        color: selected
            ? theme.colorScheme.secondaryContainer.withValues(alpha: .42)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            model.selectArticle(chapter.id);
            final swipe = ZephyrSwipeDrawer.maybeOf(context);
            if (swipe != null) {
              swipe.close();
              return;
            }
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              scaffold.closeDrawer();
            }
          },
          onLongPress: compact && !showDragHandle
              ? () => _openMenu(context)
              : null,
          onSecondaryTapDown: !compact
              ? (details) => _openMenu(
                    context,
                    position: secondaryMenuPosition(context, details),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: _textHeight,
                        ),
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: _lineGap),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            height: _textHeight,
                          ),
                        ),
                        const SizedBox(height: _previewDateGap),
                      ] else
                        const SizedBox(height: _lineGap),
                      Text(
                        metaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          height: _textHeight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showDragHandle)
                  _SidebarDragHandle<_ChapterDragData>(
                    data: _ChapterDragData(
                      articleId: chapter.id,
                      categoryId: chapter.categoryId,
                    ),
                    feedbackLabel: title,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReorderBeforeSlot<_ChapterDragData>(
          enabled: showDragHandle,
          gap: showDragHandle ? _chapterGap : _chapterGapIdle,
          horizontalInset: listInset,
          canAccept: (data) =>
              data.articleId != chapter.id &&
              data.categoryId == chapter.categoryId,
          onAccept: (data) => _acceptChapterDrop(data, insertAfter: false),
          child: body,
        ),
        _ReorderAfterGap<_ChapterDragData>(
          enabled: showDragHandle && isLast,
          gap: _chapterGap,
          horizontalInset: listInset,
          canAccept: (data) =>
              data.articleId != chapter.id &&
              data.categoryId == chapter.categoryId,
          onAccept: (data) => _acceptChapterDrop(data, insertAfter: true),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SidebarDragHandle<T extends Object> extends StatelessWidget {
  const _SidebarDragHandle({
    required this.data,
    required this.feedbackLabel,
    this.onDragStarted,
    this.onDragEnded,
  });

  static const double _iconSize = 22;
  static const double _hitSize = 36;

  final T data;
  final String feedbackLabel;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = SizedBox(
      width: _hitSize,
      height: _hitSize,
      child: Icon(
        Icons.drag_handle,
        size: _iconSize,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Draggable<T>(
      data: data,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: onDragStarted,
      onDragEnd: onDragEnded == null ? null : (_) => onDragEnded!(),
      feedback: Material(
        elevation: 4,
        borderRadius: context.zephyrBorderRadius,
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            feedbackLabel,
            style: theme.textTheme.labelLarge,
          ),
        ),
      ),
      childWhenDragging: SizedBox(
        width: _hitSize,
        height: _hitSize,
        child: Icon(
          Icons.drag_handle,
          size: _iconSize,
          color: theme.colorScheme.outline,
        ),
      ),
      child: handle,
    );
  }
}

class _LibraryDock extends StatelessWidget {
  const _LibraryDock({
    required this.model,
    required this.openLibrary,
    required this.openSettings,
  });

  final LibraryViewModel model;
  final Future<void> Function() openLibrary;
  final VoidCallback openSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: context.zephyrOutlineSide(),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: openLibrary,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    model.libraryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: openSettings,
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarResizeHandle extends StatelessWidget {
  const SidebarResizeHandle({
    super.key,
    required this.model,
    required this.maxWidth,
  });

  static const width = ZephyrResizeHandle.width;

  final LibraryViewModel model;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => ZephyrResizeHandle(
    onDragStart: () => model.setSidebarResizing(true),
    onDragUpdate: (delta) => model.resizeSidebar(
      (model.sidebarWidth + delta).clamp(
        LibraryViewModel.minSidebarWidth,
        maxWidth,
      ),
    ),
    onDragEnd: () => model.setSidebarResizing(false),
    onDragCancel: () => model.setSidebarResizing(false),
  );
}
