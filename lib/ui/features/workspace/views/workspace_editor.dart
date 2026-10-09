import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/use_cases/paragraph_indentation.dart';
import '../../../core/breakpoints.dart';
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
    this.contentTopInset = 0,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;

  /// Extra top padding so content clears a floating overlay (e.g. mobile book bar).
  final double contentTopInset;

  @override
  State<WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _WorkspaceEditorState extends State<WorkspaceEditor> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  final _controller = PlainTextEditingController();
  final _titleController = TextEditingController();

  String? _articleId;
  int? _indent;
  String _lastEmitted = '';
  var _suppressControllerNotify = false;
  var _suppressTitleNotify = false;

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferences);
    _controller.addListener(_onControllerChanged);
    _titleController.addListener(_onTitleChanged);
    _titleFocusNode.addListener(_onTitleFocusChanged);
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
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _controller.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _titleFocusNode.dispose();
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
      _suppressTitleNotify = true;
      _titleController.text = '';
      _suppressTitleNotify = false;
      return;
    }

    if (!_titleFocusNode.hasFocus &&
        (article.id != _articleId || _titleController.text != article.title)) {
      _suppressTitleNotify = true;
      _titleController.value = TextEditingValue(
        text: article.title,
        selection: TextSelection.collapsed(offset: article.title.length),
      );
      _suppressTitleNotify = false;
    }

    _indent = widget.preferences.preferences.firstLineIndent;
    final content = applyParagraphIndentation(article.content, _indent!);
    // Ignore model echoes of our own edits.
    if (article.id == _articleId && content == _lastEmitted) {
      return;
    }
    // Enter inserts an indent-only new paragraph; applyParagraphIndentation
    // normalizes those lines to empty, which would otherwise look like an
    // external edit and reset the caret to the document end via setText.
    if (article.id == _articleId &&
        applyParagraphIndentation(_controller.text, _indent!) == content) {
      return;
    }

    final keepSelection =
        article.id == _articleId ? _controller.selection : null;
    _articleId = article.id;
    _lastEmitted = content;
    _suppressControllerNotify = true;
    _controller.setText(content, selection: keepSelection);
    _suppressControllerNotify = false;
  }

  void _applyIndent(int indent) {
    _indent = indent;
    final formatted = applyParagraphIndentation(_controller.text, indent);
    if (formatted == _lastEmitted) {
      setState(() {});
      return;
    }
    final selection = _controller.selection;
    _lastEmitted = formatted;
    _suppressControllerNotify = true;
    _controller.setText(formatted, selection: selection, recordUndo: true);
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

  void _onTitleChanged() {
    if (_suppressTitleNotify || widget.model.isReadOnly) return;
    final article = widget.model.article;
    if (article == null) return;
    if (_titleController.text == article.title) return;
    widget.model.updateTitle(_titleController.text);
  }

  void _onTitleFocusChanged() {
    if (_titleFocusNode.hasFocus) {
      // Ensure the body editor releases primary focus / IME.
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
      return;
    }
    if (widget.model.isReadOnly) return;
    final trimmed = _titleController.text.trim();
    final next = trimmed.isEmpty ? 'Untitled' : trimmed;
    if (_titleController.text != next) {
      _suppressTitleNotify = true;
      _titleController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      _suppressTitleNotify = false;
    }
    final article = widget.model.article;
    if (article != null && article.title != next) {
      widget.model.updateTitle(next);
    }
  }

  /// Compact layouts keep a 12px floor so “editor width” can widen to the
  /// screen edge; desktop keeps the wider reading gutter.
  static const _compactHorizontalPadding = 12.0;
  static const _expandedHorizontalPadding = 42.0;

  double _horizontalPadding(BuildContext context) {
    final compact = ZephyrBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    return compact ? _compactHorizontalPadding : _expandedHorizontalPadding;
  }

  EditorTypography _typography(BuildContext context, EditorPreferences prefs) {
    final color = Theme.of(context).colorScheme.onSurface;
    final horizontal = _horizontalPadding(context);
    // Title block owns the top inset; body only needs a short gap below it.
    return EditorTypography(
      color: color,
      fontSize: prefs.fontSize,
      fontFamily: prefs.fontFamily,
      lineHeight: prefs.lineHeight,
      paragraphSpacing: prefs.paragraphSpacing,
      maxContentWidth: prefs.maxContentWidth,
      firstLineIndent: prefs.firstLineIndent,
      documentPadding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 48),
    );
  }

  Widget _titleHeader(BuildContext context, EditorPreferences prefs) {
    final theme = Theme.of(context);
    final horizontal = _horizontalPadding(context);
    final outline = theme.colorScheme.outlineVariant;
    final top = 20 + widget.contentTopInset;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: prefs.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                readOnly: widget.model.isReadOnly,
                maxLines: null,
                textAlign: prefs.titleCentered
                    ? TextAlign.center
                    : TextAlign.start,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: prefs.titleFontSize,
                  fontFamily: prefs.fontFamily,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: theme.colorScheme.onSurface,
                ),
                cursorColor:
                    theme.textSelectionTheme.cursorColor ??
                    theme.colorScheme.onSurface,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  hintText: 'Untitled',
                  hintStyle: theme.textTheme.titleLarge?.copyWith(
                    fontSize: prefs.titleFontSize,
                    fontFamily: prefs.fontFamily,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _focusNode.requestFocus(),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                thickness: 1,
                color: outline.withValues(alpha: 0.65),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
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
              header: _titleHeader(context, preferences),
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
