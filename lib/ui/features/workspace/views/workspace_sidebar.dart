import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_controls.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_resize_handle.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/view_models/library_view_model.dart';

enum SidebarMode { docked, drawer }

class WorkspaceSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          SizedBox(
            height: WorkspaceHeader.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (WindowChrome.leadingChromeInset > 0)
                  SizedBox(width: WindowChrome.leadingChromeInset),
                if (mode == SidebarMode.docked)
                  IconButton(
                    onPressed: model.toggleSidebar,
                    icon: const Icon(Icons.menu_open),
                    tooltip: 'Hide sidebar',
                  ),
                const Expanded(child: WindowDragArea(child: SizedBox.expand())),
              ],
            ),
          ),
          _BookPicker(model: model, library: model.library!),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: model.hasVolumes ? model.toggleAllVolumes : null,
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
                      model.isReadOnly || model.selectedBook?.isTrash == true
                      ? null
                      : model.createArticle,
                  icon: const Icon(Icons.note_add_outlined),
                  tooltip: 'New chapter',
                ),
              ],
            ),
          ),
          Expanded(
            child: _ChapterTree(model: model, library: model.library!),
          ),
          _LibraryDock(
            model: model,
            openLibrary: openLibrary,
            openSettings: openSettings,
          ),
        ],
      ),
    ),
  );
}

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.model,
    this.showMenuButton = false,
    this.showSidebarToggle = false,
  });

  static double get height => WindowChrome.titleBarHeight;

  final LibraryViewModel model;
  final bool showMenuButton;
  final bool showSidebarToggle;

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
                    onPressed: () => Scaffold.of(context).openDrawer(),
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

class _BookPicker extends StatelessWidget {
  const _BookPicker({required this.model, required this.library});

  final LibraryViewModel model;
  final WritingLibrary library;

  @override
  Widget build(BuildContext context) {
    final hostContext = context;
    final books = library.folders;
    final bookById = {for (final book in books) book.id: book};
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
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
          final stats = book == null
              ? null
              : model.bookStats(book.id);
          final meta = stats == null
              ? null
              : '${stats.volumes}卷 ${stats.chapters}章';
          final theme = Theme.of(context);
          final isTrash = book?.isTrash == true;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
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

class _ChapterTree extends StatelessWidget {
  const _ChapterTree({required this.model, required this.library});

  final LibraryViewModel model;
  final WritingLibrary library;

  @override
  Widget build(BuildContext context) {
    final bookId = model.selectedBook?.id;
    if (bookId == null) return const SizedBox();
    final chapters = library.articles
        .where((item) => item.folderId == bookId)
        .toList();
    final isTrash = bookId == WritingFolder.trashId;
    final entries = <Object>[];
    for (final volume in library.categories.where(
      (item) => !isTrash && item.folderId == bookId,
    )) {
      entries.add(volume);
      if (model.isVolumeExpanded(volume.id)) {
        entries.addAll(chapters.where((item) => item.categoryId == volume.id));
      }
    }
    final loose = chapters.where((item) => isTrash || item.categoryId == null);
    if (loose.isNotEmpty) {
      if (!isTrash) entries.add(_LooseChapters.label);
      entries.addAll(loose);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        WritingCategory volume => _VolumeRow(
          volume: volume,
          model: model,
          chapterCount: chapters
              .where((item) => item.categoryId == volume.id)
              .length,
        ),
        ArticleSummary chapter => _ChapterRow(chapter: chapter, model: model),
        _LooseChapters() => const Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Text('Unfiled chapters'),
        ),
        _ => const SizedBox(),
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.volume,
    required this.model,
    required this.chapterCount,
  });

  static const _listInset = 6.0;
  static const _volumeGap = 6.0;

  final WritingCategory volume;
  final LibraryViewModel model;
  final int chapterCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_listInset, _volumeGap, _listInset, 0),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: theme.colorScheme.outline,
            width: ZephyrControls.borderWidth,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => model.toggleVolume(volume.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.model});

  static const _listInset = 6.0;
  static const _lineGap = 4.0;
  static const _previewDateGap = 2.0;

  final ArticleSummary chapter;
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    final activeArticle = model.article?.id == chapter.id ? model.article : null;
    final selected = activeArticle != null;
    final metaText =
        '${_formatDate(chapter.createdAt)} - ${_formatDate(activeArticle?.updatedAt ?? chapter.updatedAt)} - ${activeArticle?.wordCount ?? chapter.wordCount}字';
    return Padding(
      padding: const EdgeInsets.fromLTRB(_listInset, 2, _listInset, 0),
      child: Material(
        color: selected
            ? theme.colorScheme.secondaryContainer.withValues(alpha: .42)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          borderRadius: radius,
          onTap: () => model.selectArticle(chapter.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title.isEmpty ? 'Untitled' : chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(height: 1.35),
                ),
                if (chapter.summary.isNotEmpty) ...[
                  const SizedBox(height: _lineGap),
                  Text(
                    chapter.summary.replaceAll(RegExp(r'[\r\n\u3000]'), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: _previewDateGap),
                ] else
                  const SizedBox(height: _lineGap),
                Text(
                  metaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
          side: BorderSide(color: theme.colorScheme.outline),
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

enum _LooseChapters { label }

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
