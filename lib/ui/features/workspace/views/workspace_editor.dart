import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/use_cases/paragraph_indentation.dart';
import '../../editor/plain_text/input/plain_text_editing_controller.dart';
import '../../editor/plain_text/layout/editor_typography.dart';
import '../../editor/plain_text/zephyr_plain_text_editor.dart';
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
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _controller = PlainTextEditingController();

  String? _articleId;
  int? _indent;
  String _lastEmitted = '';
  var _suppressControllerNotify = false;

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferences);
    _controller.addListener(_onControllerChanged);
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
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPreferences() {
    final indent = widget.preferences.preferences.firstLineIndent;
    if (indent != _indent) {
      _applyIndent(indent);
      return;
    }
    setState(() {});
  }

  void _syncFromModel() {
    final article = widget.model.article;
    if (article == null) {
      _articleId = null;
      _suppressControllerNotify = true;
      _controller.setText('');
      _suppressControllerNotify = false;
      _lastEmitted = '';
      return;
    }
    _indent = widget.preferences.preferences.firstLineIndent;
    final content = applyParagraphIndentation(article.content, _indent!);
    // Ignore model echoes of our own edits.
    if (article.id == _articleId && content == _lastEmitted) {
      return;
    }

    _articleId = article.id;
    _lastEmitted = content;
    _suppressControllerNotify = true;
    _controller.setText(content);
    _suppressControllerNotify = false;
  }

  void _applyIndent(int indent) {
    _indent = indent;
    final formatted = applyParagraphIndentation(_controller.text, indent);
    if (formatted == _lastEmitted) {
      setState(() {});
      return;
    }
    _lastEmitted = formatted;
    _suppressControllerNotify = true;
    _controller.setText(formatted, recordUndo: true);
    _suppressControllerNotify = false;
    setState(() {});
    widget.model.updateContent(formatted);
  }

  void _onControllerChanged() {
    if (_suppressControllerNotify || widget.model.isReadOnly) return;
    final plain = _controller.text;
    if (plain == _lastEmitted) return;
    _lastEmitted = plain;
    widget.model.updateContent(plain);
  }

  EditorTypography _typography(BuildContext context, EditorPreferences prefs) {
    final color = Theme.of(context).colorScheme.onSurface;
    return EditorTypography(
      color: color,
      fontSize: prefs.fontSize,
      fontFamily: prefs.fontFamily,
      lineHeight: prefs.lineHeight,
      paragraphSpacing: prefs.paragraphSpacing,
      maxContentWidth: prefs.maxContentWidth,
      firstLineIndent: prefs.firstLineIndent,
      documentPadding: const EdgeInsets.fromLTRB(42, 28, 42, 48),
    );
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
    final theme = Theme.of(context);
    final selectionColor = theme.colorScheme.primary.withValues(alpha: 0.35);
    final cursorColor =
        theme.textSelectionTheme.cursorColor ?? theme.colorScheme.onSurface;
    final typography = _typography(context, preferences);

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ZephyrPlainTextEditor(
              controller: _controller,
              typography: typography,
              scrollController: _scrollController,
              focusNode: _focusNode,
              readOnly: widget.model.isReadOnly,
              cursorColor: cursorColor,
              selectionColor: selectionColor,
              onTextChanged: (_) {},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 14,
          child: IgnorePointer(
            child: Text(
              '${article.wordCount} characters',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ],
    );
  }
}
