import 'package:flutter/material.dart';

import '../view_models/library_view_model.dart';

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
      if (model.error != null) {
        return Scaffold(
          body: Center(child: Text('Could not open Room.db: ${model.error}')),
        );
      }
      final library = model.library;
      if (library == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final article = model.article;
      if (article != null && _controller.text != article.content) {
        _controller.text = article.content;
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Zephyr'),
          actions: [
            IconButton(
              onPressed: model.createArticle,
              icon: const Icon(Icons.add),
              tooltip: 'New article',
            ),
          ],
        ),
        body: Row(
          children: [
            SizedBox(
              width: 280,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: ListView(
                  children: [
                    for (final folder in library.folders) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          folder.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      for (final item in library.articles.where(
                        (item) => item.folderId == folder.id,
                      ))
                        ListTile(
                          selected: item.id == article?.id,
                          title: Text(item.title),
                          subtitle: Text(
                            item.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => model.selectArticle(item.id),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: article == null
                  ? const Center(
                      child: Text('Create an article to begin writing.'),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: TextField(
                        controller: _controller,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(height: 1.65),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: article.title,
                        ),
                        onChanged: model.updateContent,
                      ),
                    ),
            ),
          ],
        ),
      );
    },
  );
}
