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
  static const _desktopBreakpoint = 720.0;
  static const _sidebarWidth = 320.0;
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
      if (model.error != null) {
        return _ErrorPage(error: model.error!);
      }
      if (model.library == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _desktopBreakpoint;
          return _buildScaffold(context, model, compact);
        },
      );
    },
  );

  Widget _buildScaffold(
    BuildContext context,
    LibraryViewModel model,
    bool compact,
  ) {
    final library = model.library!;
    final navigation = _BookNavigation(model: model, library: library);
    return Scaffold(
      appBar: AppBar(
        title: Text(model.libraryName),
        actions: [
          IconButton(
            onPressed: _openLibrary,
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Open library',
          ),
          IconButton(
            onPressed: model.isReadOnly ? null : model.createArticle,
            icon: const Icon(Icons.note_add_outlined),
            tooltip: 'New chapter',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: compact ? Drawer(child: SafeArea(child: navigation)) : null,
      body: compact
          ? _Editor(model: model, controller: _controller)
          : Row(
              children: [
                SizedBox(width: _sidebarWidth, child: navigation),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Editor(model: model, controller: _controller),
                ),
              ],
            ),
    );
  }

  Future<void> _openLibrary() async {
    final root = await FilePicker.getDirectoryPath();
    if (root != null) await widget.viewModel.openLibrary(root);
  }
}

class _BookNavigation extends StatelessWidget {
  const _BookNavigation({required this.model, required this.library});
  final LibraryViewModel model;
  final WritingLibrary library;

  @override
  Widget build(BuildContext context) {
    final entries = _entriesFor(model, library);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButton<String>(
              value: model.selectedBook?.id,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: library.folders
                  .map(
                    (book) => DropdownMenuItem(
                      value: book.id,
                      child: Text(book.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (bookId) {
                if (bookId != null) {
                  model.selectBook(bookId);
                }
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _NavigationRow(entry: entries[index], model: model),
            ),
          ),
        ],
      ),
    );
  }

  List<_NavigationEntry> _entriesFor(
    LibraryViewModel model,
    WritingLibrary library,
  ) {
    final bookId = model.selectedBook?.id;
    if (bookId == null) return const [];
    final entries = <_NavigationEntry>[];
    final volumes = library.categories.where(
      (volume) => volume.folderId == bookId,
    );
    final chapters = library.articles
        .where((chapter) => chapter.folderId == bookId)
        .toList(growable: false);
    for (final volume in volumes) {
      entries.add(_NavigationEntry.volume(volume));
      if (model.isVolumeExpanded(volume.id)) {
        entries.addAll(
          chapters
              .where((chapter) => chapter.categoryId == volume.id)
              .map(_NavigationEntry.chapter),
        );
      }
    }
    final uncategorized = chapters.where(
      (chapter) => chapter.categoryId == null,
    );
    if (uncategorized.isNotEmpty) {
      entries.add(const _NavigationEntry.uncategorized());
      entries.addAll(uncategorized.map(_NavigationEntry.chapter));
    }
    return entries;
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({required this.entry, required this.model});
  final _NavigationEntry entry;
  final LibraryViewModel model;

  @override
  Widget build(BuildContext context) => switch (entry) {
    _VolumeEntry(:final volume) => ListTile(
      dense: true,
      leading: Icon(
        model.isVolumeExpanded(volume.id)
            ? Icons.keyboard_arrow_down
            : Icons.keyboard_arrow_right,
      ),
      title: Text(volume.name, overflow: TextOverflow.ellipsis),
      onTap: () => model.toggleVolume(volume.id),
    ),
    _UncategorizedEntry() => const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text('Uncategorized'),
    ),
    _ChapterEntry(:final chapter) => ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 44, right: 16),
      leading: const Icon(Icons.description_outlined, size: 18),
      selected: chapter.id == model.article?.id,
      title: Text(chapter.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => model.selectArticle(chapter.id),
    ),
  };
}

sealed class _NavigationEntry {
  const _NavigationEntry();
  factory _NavigationEntry.volume(WritingCategory volume) = _VolumeEntry;
  factory _NavigationEntry.chapter(ArticleSummary chapter) = _ChapterEntry;
  const factory _NavigationEntry.uncategorized() = _UncategorizedEntry;
}

class _VolumeEntry extends _NavigationEntry {
  const _VolumeEntry(this.volume);
  final WritingCategory volume;
}

class _ChapterEntry extends _NavigationEntry {
  const _ChapterEntry(this.chapter);
  final ArticleSummary chapter;
}

class _UncategorizedEntry extends _NavigationEntry {
  const _UncategorizedEntry();
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: TextField(
            controller: controller,
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
        ),
      ),
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
          'Could not open the library: $error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
