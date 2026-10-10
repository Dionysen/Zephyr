import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../view_models/quick_toolbar_view_model.dart';

Future<void> showQuickToolbarEditSheet(
  BuildContext context, {
  required QuickToolbarViewModel toolbar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: toolbar,
        builder: (context, _) => _QuickToolbarEditBody(
          toolbar: toolbar,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

class _QuickToolbarEditBody extends StatelessWidget {
  const _QuickToolbarEditBody({
    required this.toolbar,
    required this.scrollController,
  });

  final QuickToolbarViewModel toolbar;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = toolbar.config;
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final emptyStyle = ZephyrBottomSheet.bodyStyle(theme);
    return Material(
      color: theme.colorScheme.surface,
      child: ZephyrBottomSheet.listTheme(
        context: context,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              l10n.quickToolbarEdit,
              style: ZephyrBottomSheet.titleStyle(theme),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.quickToolbarEditHint,
              style: emptyStyle,
            ),
            const SizedBox(height: 12),
            Text(l10n.quickToolbarPinnedSection, style: sectionStyle),
            const SizedBox(height: 4),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: config.pinnedIds.length,
              onReorderItem: toolbar.reorderPinned,
              itemBuilder: (context, index) {
                final id = config.pinnedIds[index];
                final tool = config.toolById(id);
                if (tool == null) return SizedBox(key: ValueKey(id));
                return _ToolEditTile(
                  key: ValueKey(id),
                  index: index,
                  title: _title(l10n, tool),
                  subtitle:
                      tool.kind == QuickToolKind.phrase ? tool.payload : null,
                  onMoveToCustom: () => toolbar.moveToCustom(id),
                  onRemove: () => toolbar.removeTool(id),
                  onEditPhrase: tool.kind == QuickToolKind.phrase
                      ? () => _editPhrase(context, toolbar, tool)
                      : null,
                );
              },
            ),
            if (config.pinnedIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.quickToolbarSectionEmpty,
                  style: emptyStyle,
                ),
              ),
            const SizedBox(height: 12),
            Text(l10n.quickToolbarCustomSection, style: sectionStyle),
            const SizedBox(height: 4),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: config.customIds.length,
              onReorderItem: toolbar.reorderCustom,
              itemBuilder: (context, index) {
                final id = config.customIds[index];
                final tool = config.toolById(id);
                if (tool == null) return SizedBox(key: ValueKey(id));
                return _ToolEditTile(
                  key: ValueKey(id),
                  index: index,
                  title: _title(l10n, tool),
                  subtitle:
                      tool.kind == QuickToolKind.phrase ? tool.payload : null,
                  onMoveToPinned:
                      config.pinnedIds.length < QuickToolbarConfig.maxPinned
                          ? () => toolbar.moveToPinned(id)
                          : null,
                  onRemove: () => toolbar.removeTool(id),
                  onEditPhrase: tool.kind == QuickToolKind.phrase
                      ? () => _editPhrase(context, toolbar, tool)
                      : null,
                );
              },
            ),
            if (config.customIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.quickToolbarSectionEmpty,
                  style: emptyStyle,
                ),
              ),
            const SizedBox(height: 12),
            Text(l10n.quickToolbarAddSection, style: sectionStyle),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tool in config.availableBuiltins)
                  ActionChip(
                    label: Text(_title(l10n, tool)),
                    onPressed: () => toolbar.addBuiltin(tool),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(l10n.quickToolbarAddPhrase),
                  onPressed: () => _addPhrase(context, toolbar),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n, QuickTool tool) => switch (tool.kind) {
    QuickToolKind.tools => l10n.quickToolbarToolsTooltip,
    QuickToolKind.undo => l10n.quickToolbarUndoTooltip,
    QuickToolKind.paste => l10n.quickToolbarPasteTooltip,
    QuickToolKind.indent => l10n.quickToolbarIndentTooltip,
    QuickToolKind.format => l10n.quickToolbarFormatTooltip,
    QuickToolKind.phrase => tool.label ?? l10n.quickToolbarAddPhrase,
  };

  Future<void> _addPhrase(
    BuildContext context,
    QuickToolbarViewModel toolbar,
  ) async {
    final result = await _showPhraseDialog(context);
    if (result == null) return;
    toolbar.addPhrase(label: result.$1, payload: result.$2);
  }

  Future<void> _editPhrase(
    BuildContext context,
    QuickToolbarViewModel toolbar,
    QuickTool tool,
  ) async {
    final result = await _showPhraseDialog(
      context,
      initialLabel: tool.label ?? '',
      initialPayload: tool.payload ?? '',
    );
    if (result == null) return;
    toolbar.updatePhrase(tool.id, label: result.$1, payload: result.$2);
  }

  Future<(String, String)?> _showPhraseDialog(
    BuildContext context, {
    String initialLabel = '',
    String initialPayload = '',
  }) {
    return showDialog<(String, String)>(
      context: context,
      builder: (context) => _PhraseDialog(
        initialLabel: initialLabel,
        initialPayload: initialPayload,
      ),
    );
  }
}

class _PhraseDialog extends StatefulWidget {
  const _PhraseDialog({
    required this.initialLabel,
    required this.initialPayload,
  });

  final String initialLabel;
  final String initialPayload;

  @override
  State<_PhraseDialog> createState() => _PhraseDialogState();
}

class _PhraseDialogState extends State<_PhraseDialog> {
  late final TextEditingController _label;
  late final TextEditingController _payload;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initialLabel);
    _payload = TextEditingController(text: widget.initialPayload);
  }

  @override
  void dispose() {
    _label.dispose();
    _payload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.quickToolbarAddPhrase),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: l10n.quickToolbarPhraseName),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _payload,
            decoration: InputDecoration(
              labelText: l10n.quickToolbarPhraseContent,
            ),
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_label.text, _payload.text)),
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

class _ToolEditTile extends StatelessWidget {
  const _ToolEditTile({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.onMoveToPinned,
    this.onMoveToCustom,
    this.onRemove,
    this.onEditPhrase,
  });

  final int index;
  final String title;
  final String? subtitle;
  final VoidCallback? onMoveToPinned;
  final VoidCallback? onMoveToCustom;
  final VoidCallback? onRemove;
  final VoidCallback? onEditPhrase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEditPhrase != null)
            IconButton(
              tooltip: l10n.actionRename,
              onPressed: onEditPhrase,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onMoveToPinned != null)
            IconButton(
              tooltip: l10n.quickToolbarMoveToPinned,
              onPressed: onMoveToPinned,
              icon: const Icon(Icons.arrow_upward),
            ),
          if (onMoveToCustom != null)
            IconButton(
              tooltip: l10n.quickToolbarMoveToCustom,
              onPressed: onMoveToCustom,
              icon: const Icon(Icons.arrow_downward),
            ),
          IconButton(
            tooltip: l10n.actionDelete,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
