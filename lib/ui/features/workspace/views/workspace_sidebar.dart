import 'package:flutter/material.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../core/window_chrome.dart';
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

  static const width = 334.0;

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
              children: [
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
            padding: const EdgeInsets.only(bottom: 8),
            child: IconButton(
              onPressed: model.isReadOnly ? null : model.createArticle,
              icon: const Icon(Icons.note_add_outlined),
              tooltip: 'New chapter',
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
  });

  static const height = 42.0;

  final LibraryViewModel model;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = model.article?.title.trim();
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const WindowDragArea(child: SizedBox.expand()),
            if (showMenuButton)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open library',
                ),
              ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showMenuButton ? 48 : 16,
                ),
                child: Text(
                  title?.isNotEmpty == true ? title! : 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: WindowCaptionButtons(),
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
    child: DropdownButtonFormField<String>(
      initialValue: model.selectedBook?.id,
      isExpanded: true,
      borderRadius: BorderRadius.circular(8),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(),
      ),
      items: library.folders
          .where((book) => book.id != 'PW_Trash')
          .map(
            (book) => DropdownMenuItem(value: book.id, child: Text(book.name)),
          )
          .toList(growable: false),
      onChanged: (id) {
        if (id != null) model.selectBook(id);
      },
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
              const Icon(Icons.menu_book_outlined, size: 19),
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
                icon: const Icon(Icons.settings_outlined, size: 19),
                tooltip: 'Settings',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum _LooseChapters { label }
