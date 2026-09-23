import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../view_models/library_view_model.dart';

/// The presentation-only writing workspace. Document state belongs to the
/// ViewModel; this widget only renders and animates it.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.viewModel});
  final LibraryViewModel viewModel;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.save();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final model = widget.viewModel;
      if (model.error != null) return _ErrorPage(error: model.error!);
      if (model.library == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 720
            ? _MobileWorkspace(
                model: model,
                controller: _controller,
                openLibrary: _openLibrary,
              )
            : _DesktopWorkspace(
                model: model,
                controller: _controller,
                openLibrary: _openLibrary,
              ),
      );
    },
  );

  Future<void> _openLibrary() async {
    final root = await FilePicker.getDirectoryPath();
    if (root != null) await widget.viewModel.openLibrary(root);
  }
}

class _DesktopWorkspace extends StatelessWidget {
  const _DesktopWorkspace({
    required this.model,
    required this.controller,
    required this.openLibrary,
  });
  static const sidebarWidth = 334.0;
  final LibraryViewModel model;
  final TextEditingController controller;
  final Future<void> Function() openLibrary;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: model.isSidebarExpanded ? sidebarWidth : 0,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: sidebarWidth,
                  maxWidth: sidebarWidth,
                  child: _Sidebar(model: model, openLibrary: openLibrary),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _TitleBar(model: model),
                  Expanded(
                    child: _Editor(model: model, controller: controller),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!model.isSidebarExpanded)
          Positioned(
            top: 0,
            left: 0,
            child: IconButton(
              onPressed: model.toggleSidebar,
              icon: const Icon(Icons.menu_open),
              tooltip: 'Open sidebar',
            ),
          ),
      ],
    ),
  );
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.model});
  static const height = 42.0;
  final LibraryViewModel model;

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
            DragToMoveArea(child: const SizedBox.expand()),
            Center(
              child: Text(
                title?.isNotEmpty == true ? title! : 'Untitled',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (Platform.isWindows)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 138,
                  child: WindowCaption(
                    brightness: theme.brightness,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.model, required this.openLibrary});
  final LibraryViewModel model;
  final Future<void> Function() openLibrary;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    child: Column(
      children: [
        SizedBox(
          height: _TitleBar.height,
          child: Row(
            children: [
              IconButton(
                onPressed: model.toggleSidebar,
                icon: const Icon(Icons.menu_open),
                tooltip: 'Hide sidebar',
              ),
              const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
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
        _DirectoryPill(model: model, openLibrary: openLibrary),
      ],
    ),
  );
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
      borderRadius: BorderRadius.circular(6),
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

class _DirectoryPill extends StatelessWidget {
  const _DirectoryPill({required this.model, required this.openLibrary});
  final LibraryViewModel model;
  final Future<void> Function() openLibrary;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(28),
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
              const Icon(Icons.settings_outlined, size: 19),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MobileWorkspace extends StatelessWidget {
  const _MobileWorkspace({
    required this.model,
    required this.controller,
    required this.openLibrary,
  });
  final LibraryViewModel model;
  final TextEditingController controller;
  final Future<void> Function() openLibrary;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        model.article?.title.isNotEmpty == true
            ? model.article!.title
            : 'Untitled',
      ),
      actions: [
        IconButton(
          onPressed: openLibrary,
          icon: const Icon(Icons.folder_open_outlined),
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: _Sidebar(model: model, openLibrary: openLibrary),
      ),
    ),
    body: _Editor(model: model, controller: controller),
  );
}

class _Editor extends StatelessWidget {
  const _Editor({required this.model, required this.controller});
  final LibraryViewModel model;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final article = model.article;
    if (article == null) {
      return const Center(
        child: Text('Choose or create a chapter to begin writing.'),
      );
    }
    if (controller.text != article.content) {
      controller.text = article.content;
    }
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(42, 28, 42, 42),
              child: TextField(
                controller: controller,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.75),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing...',
                ),
                onChanged: model.isReadOnly ? null : model.updateContent,
              ),
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 14,
          child: Text(
            '${article.content.runes.length} characters',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not open library: $error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

enum _LooseChapters { label }
