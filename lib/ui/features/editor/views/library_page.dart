import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../view_models/library_view_model.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.viewModel});

  final LibraryViewModel viewModel;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _sidebarWidth = 328.0;
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
    builder: (context, _) => _buildPage(context, widget.viewModel),
  );

  Widget _buildPage(BuildContext context, LibraryViewModel model) {
    if (model.error != null) return _buildError(model);
    final library = model.library;
    if (library == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final article = model.article;
    if (article != null && _controller.text != article.content) {
      _controller.text = article.content;
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildTitleBar(model),
      body: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: model.isSidebarExpanded ? _sidebarWidth : 0,
              child: ClipRect(
                child: _LibrarySidebar(
                  model: model,
                  library: library,
                  onOpenLibrary: _openLibrary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: model.isSidebarExpanded ? 1 : 0,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(child: _buildEditor(context, model, article)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTitleBar(LibraryViewModel model) => AppBar(
    toolbarHeight: 64,
    leadingWidth: 132,
    leading: Padding(
      padding: const EdgeInsets.only(left: 72),
      child: IconButton(
        onPressed: model.toggleSidebar,
        icon: Icon(model.isSidebarExpanded ? Icons.menu_open : Icons.menu),
        tooltip: model.isSidebarExpanded ? 'Hide sidebar' : 'Show sidebar',
      ),
    ),
    titleSpacing: 0,
    centerTitle: true,
    title: Text(
      model.article?.title.isNotEmpty == true
          ? model.article!.title
          : model.bookName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    actions: [
      IconButton(
        onPressed: _openLibrary,
        icon: const Icon(Icons.folder_open_outlined),
        tooltip: 'Open book',
      ),
      IconButton(
        onPressed: model.isReadOnly ? null : model.createArticle,
        icon: const Icon(Icons.note_add_outlined),
        tooltip: 'New chapter',
      ),
      const SizedBox(width: 12),
    ],
  );

  Widget _buildEditor(
    BuildContext context,
    LibraryViewModel model,
    WritingArticle? article,
  ) => article == null
      ? const Center(
          child: Text('Choose or create a chapter to begin writing.'),
        )
      : Padding(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(height: 1.75),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: article.title,
            ),
            onChanged: model.isReadOnly ? null : model.updateContent,
          ),
        );

  Widget _buildError(LibraryViewModel model) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          model.isLibraryInUse
              ? 'This book is already open in another Zephyr window.\n'
                    'Close that window before opening Zephyr again.'
              : 'Could not open the book: ${model.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );

  Future<void> _openLibrary() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) await widget.viewModel.openLibrary(path);
  }
}

class _LibrarySidebar extends StatelessWidget {
  const _LibrarySidebar({
    required this.model,
    required this.library,
    required this.onOpenLibrary,
  });

  final LibraryViewModel model;
  final WritingLibrary library;
  final Future<void> Function() onOpenLibrary;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _BookPicker(
            bookName: model.bookName,
            onOpenLibrary: onOpenLibrary,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final folder in library.folders)
                _FolderTreeNode(
                  folder: folder,
                  chapters: library.articles
                      .where((article) => article.folderId == folder.id)
                      .toList(growable: false),
                  expanded: model.isFolderExpanded(folder.id),
                  selectedArticleId: model.article?.id,
                  onToggle: () => model.toggleFolder(folder.id),
                  onSelect: model.selectArticle,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BookPicker extends StatelessWidget {
  const _BookPicker({required this.bookName, required this.onOpenLibrary});

  final String bookName;
  final Future<void> Function() onOpenLibrary;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_BookMenuAction>(
    tooltip: 'Choose book',
    onSelected: (action) {
      if (action == _BookMenuAction.open) onOpenLibrary();
    },
    itemBuilder: (context) => const [
      PopupMenuItem(
        enabled: false,
        value: _BookMenuAction.current,
        child: Text('Current book'),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: _BookMenuAction.open,
        child: ListTile(
          leading: Icon(Icons.folder_open_outlined),
          title: Text('Open another book…'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
    child: Ink(
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(bookName, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    ),
  );
}

enum _BookMenuAction { current, open }

class _FolderTreeNode extends StatelessWidget {
  const _FolderTreeNode({
    required this.folder,
    required this.chapters,
    required this.expanded,
    required this.selectedArticleId,
    required this.onToggle,
    required this.onSelect,
  });

  final WritingFolder folder;
  final List<ArticleSummary> chapters;
  final bool expanded;
  final String? selectedArticleId;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
              ),
              const SizedBox(width: 4),
              Icon(
                expanded ? Icons.folder_open_outlined : Icons.folder_outlined,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(folder.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 160),
        crossFadeState: expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: const SizedBox.shrink(),
        secondChild: Column(
          children: [
            for (final chapter in chapters)
              _ChapterLeaf(
                chapter: chapter,
                selected: chapter.id == selectedArticleId,
                onTap: () => onSelect(chapter.id),
              ),
          ],
        ),
      ),
    ],
  );
}

class _ChapterLeaf extends StatelessWidget {
  const _ChapterLeaf({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final ArticleSummary chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Ink(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 8, 16, 8),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                chapter.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
