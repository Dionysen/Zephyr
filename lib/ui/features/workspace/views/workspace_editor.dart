import 'package:flutter/material.dart';

import '../../../../domain/use_cases/paragraph_indentation.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';

class WorkspaceEditor extends StatefulWidget {
  const WorkspaceEditor({
    super.key,
    required this.model,
    required this.preferences,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;

  @override
  State<WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _WorkspaceEditorState extends State<WorkspaceEditor> {
  final _controller = TextEditingController();
  String? _articleId;
  int? _indent;

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferences);
    _syncFromModel();
  }

  @override
  void didUpdateWidget(WorkspaceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      oldWidget.preferences.removeListener(_onPreferences);
      widget.preferences.addListener(_onPreferences);
    }
    _syncFromModel();
  }

  @override
  void dispose() {
    widget.preferences.removeListener(_onPreferences);
    _controller.dispose();
    super.dispose();
  }

  void _onPreferences() {
    final indent = widget.preferences.preferences.firstLineIndent;
    if (indent != _indent) {
      _applyIndent(indent);
    }
    setState(() {});
  }

  void _syncFromModel() {
    final article = widget.model.article;
    if (article?.id == _articleId) {
      return;
    }
    _articleId = article?.id;
    _indent = widget.preferences.preferences.firstLineIndent;
    _controller.text = article == null
        ? ''
        : applyParagraphIndentation(article.content, _indent!);
  }

  void _applyIndent(int indent) {
    _indent = indent;
    final formatted = applyParagraphIndentation(_controller.text, indent);
    if (formatted != _controller.text) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.model.article;
    if (article == null) {
      return const Center(
        child: Text('Choose or create a chapter to begin writing.'),
      );
    }
    final preferences = widget.preferences.preferences;
    return Stack(
      children: [
        SizedBox.expand(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: preferences.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(42, 28, 42, 42),
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  readOnly: widget.model.isReadOnly,
                  textAlignVertical: TextAlignVertical.top,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: preferences.fontFamily,
                    fontSize: preferences.fontSize,
                    height:
                        preferences.lineHeight +
                        preferences.paragraphSpacing / preferences.fontSize,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Start writing...',
                  ),
                  onChanged: widget.model.isReadOnly ? null : _onChanged,
                ),
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

  void _onChanged(String text) {
    final indent = widget.preferences.preferences.firstLineIndent;
    final formatted = applyParagraphIndentation(text, indent);
    if (formatted != text) {
      final selection = _controller.selection;
      final offset = (selection.baseOffset + formatted.length - text.length)
          .clamp(0, formatted.length)
          .toInt();
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: offset),
      );
    }
    widget.model.updateContent(formatted);
  }
}
