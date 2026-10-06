import 'package:flutter/material.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_resize_handle.dart';
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
                const Spacer(),
                IconButton(
                  onPressed: model.isReadOnly ? null : model.createArticle,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
    child: ZephyrDropdown<String>(
      value: model.selectedBook?.id,
      hint: 'Select a book',
      items: [
        for (final book in library.folders.where(
          (book) => book.id != 'PW_Trash',
        ))
          ZephyrDropdownItem(value: book.id, label: book.name),
      ],
      onChanged: model.selectBook,
    ),
  );
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
    final entries = <Object>[];
    for (final volume in library.categories.where(
      (item) => item.folderId == bookId,
    )) {
      entries.add(volume);
      if (model.isVolumeExpanded(volume.id)) {
        entries.addAll(chapters.where((item) => item.categoryId == volume.id));
      }
    }
    final loose = chapters.where((item) => item.categoryId == null);
    if (loose.isNotEmpty) {
      entries
        ..add(_LooseChapters.label)
        ..addAll(loose);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        WritingCategory volume => _VolumeRow(volume: volume, model: model),
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
  const _VolumeRow({required this.volume, required this.model});

  final WritingCategory volume;
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => model.toggleVolume(volume.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
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
                child: Text(
                  volume.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.model});

  final ArticleSummary chapter;
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) {
    final date = chapter.updatedAt;
    final dateText =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Material(
      color: chapter.id == model.article?.id
          ? Theme.of(context).colorScheme.secondaryContainer
                .withValues(alpha: .42)
          : Colors.transparent,
      child: InkWell(
        onTap: () => model.selectArticle(chapter.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 9, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title.isEmpty ? 'Untitled' : chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (chapter.summary.isNotEmpty)
                Text(
                  chapter.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(dateText, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
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
