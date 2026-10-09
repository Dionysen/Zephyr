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
    this.showWordCount = true,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;

  /// Extra top padding so content clears a floating overlay (e.g. mobile book bar).
  final double contentTopInset;

  /// When false, the host (e.g. mobile chrome) owns the word-count capsule.
  final bool showWordCount;

  @override
  State<WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _WorkspaceEditorState extends State<WorkspaceEditor> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  final _controller = PlainTextEditingController();
  final _titleController = TextEditingController();

  /// Last caret per article for the current editor session.
  final Map<String, TextSelection> _carets = {};

  /// Last scroll offset per article for the current editor session.
  final Map<String, double> _scrolls = {};

  String? _articleId;
  int? _indent;
  String _lastEmitted = '';
  var _suppressControllerNotify = false;
  var _suppressTitleNotify = false;
  var _showJumpToEnd = false;
  var _ignoreScrollForJump = false;
  var _lastJumpScroll = 0.0;

  @override
  void initState() {
    super.initState();
    widget.preferences.addListener(_onPreferences);
    _controller.addListener(_onControllerChanged);
    _titleController.addListener(_onTitleChanged);
    _titleFocusNode.addListener(_onTitleFocusChanged);
    _scrollController.addListener(_onScrollForJumpChip);
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
    _persistEditorPosition();
    widget.preferences.removeListener(_onPreferences);
    _controller.removeListener(_onControllerChanged);
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _scrollController.removeListener(_onScrollForJumpChip);
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

  void _persistEditorPosition() {
    final id = _articleId;
    if (id == null) return;
    _carets[id] = _controller.selection;
    if (_scrollController.hasClients) {
      _scrolls[id] = _scrollController.offset;
    }
  }

  void _restoreScroll(String articleId) {
    if (!_scrollController.hasClients) return;
    final saved = _scrolls[articleId] ?? 0.0;
    final max = _scrollController.position.maxScrollExtent;
    _ignoreScrollForJump = true;
    _scrollController.jumpTo(saved.clamp(0.0, max));
    _ignoreScrollForJump = false;
    _lastJumpScroll = _scrollController.offset;
  }

  bool _isScrollAtEnd() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    return max <= 8 || _scrollController.offset >= max - 32;
  }

  void _dismissJumpToEnd() {
    if (!_showJumpToEnd) return;
    setState(() => _showJumpToEnd = false);
  }

  /// Keep the chip while scrolling down; dismiss on scroll-up or reaching end.
  void _onScrollForJumpChip() {
    if (_ignoreScrollForJump || !_showJumpToEnd) return;
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if (_isScrollAtEnd()) {
      _lastJumpScroll = offset;
      _dismissJumpToEnd();
      return;
    }
    final delta = offset - _lastJumpScroll;
    _lastJumpScroll = offset;
    if (delta < -1.5) {
      _dismissJumpToEnd();
    }
  }

  void _jumpToEnd() {
    final len = _controller.text.length;
    _suppressControllerNotify = true;
    _controller.setSelection(TextSelection.collapsed(offset: len));
    _suppressControllerNotify = false;
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      _ignoreScrollForJump = true;
      _scrollController
          .animateTo(
            max,
            duration: const Duration(milliseconds: 280),
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
          )
          .whenComplete(() {
            if (!mounted) return;
            _ignoreScrollForJump = false;
            _lastJumpScroll = _scrollController.hasClients
                ? _scrollController.offset
                : max;
          });
    }
    _focusNode.requestFocus();
    _dismissJumpToEnd();
  }

  void _onSelectionChanged(TextSelection selection) {
    if (!_showJumpToEnd) return;
    // Manual focus at document end dismisses the chip.
    if (selection.extentOffset >= _controller.text.length &&
        _isScrollAtEnd()) {
      _dismissJumpToEnd();
    }
  }

  void _syncFromModel() {
    final article = widget.model.article;
    if (article == null) {
      _persistEditorPosition();
      _articleId = null;
      _suppressControllerNotify = true;
      _controller.setText('');
      _suppressControllerNotify = false;
      _lastEmitted = '';
      _suppressTitleNotify = true;
      _titleController.text = '';
      _suppressTitleNotify = false;
      if (_showJumpToEnd) {
        setState(() => _showJumpToEnd = false);
      }
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

    final switching = article.id != _articleId;
    if (switching && _articleId != null) {
      _persistEditorPosition();
    }

    final keepSelection = switching
        ? _carets[article.id]
        : _controller.selection;
    _articleId = article.id;
    _lastEmitted = content;
    _suppressControllerNotify = true;
    _controller.setText(content, selection: keepSelection);
    _suppressControllerNotify = false;

    if (switching) {
      // Decide after layout: show when the chapter opens away from the end.
      _showJumpToEnd = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _articleId != article.id) return;
        _restoreScroll(article.id);
        if (!_scrollController.hasClients) return;
        _lastJumpScroll = _scrollController.offset;
        final show = !_isScrollAtEnd();
        if (show != _showJumpToEnd) {
          setState(() => _showJumpToEnd = show);
        }
      });
    }
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
                  contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _focusNode.requestFocus(),
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
              onSelectionChanged: _onSelectionChanged,
            ),
          ),
        ),
        if (widget.showWordCount)
          Positioned(
            top: 12 + widget.contentTopInset,
            right: 14,
            child: IgnorePointer(
              child: EditorOverlayCapsule(
                compact: true,
                child: Text(
                  '${article.wordCount}',
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.2,
                    color: EditorOverlayCapsule.foregroundOf(context),
                  ),
                ),
              ),
            ),
          ),
        if (_showJumpToEnd)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 +
                bottomInset +
                MediaQuery.viewInsetsOf(context).bottom,
            child: Center(
              child: EditorOverlayCapsule(
                onTap: _jumpToEnd,
                child: Text(
                  '跳到文末',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: EditorOverlayCapsule.foregroundOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded-rect overlay chip: white in light mode, black in dark mode, with shadow.
class EditorOverlayCapsule extends StatelessWidget {
  const EditorOverlayCapsule({
    super.key,
    required this.child,
    this.onTap,
    this.compact = false,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Tighter padding / softer shadow for small status chips (e.g. word count).
  final bool compact;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Contrasting label color for content inside the chip.
  static Color foregroundOf(BuildContext context) {
    final onPill = _isDark(context) ? Colors.white : Colors.black;
    return onPill.withValues(alpha: 0.82);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final pillColor = (dark ? Colors.black : Colors.white).withValues(
      alpha: compact ? 0.55 : 0.72,
    );
    final shadow = Theme.of(context).colorScheme.shadow;
    // Large corners, but short of a stadium so it still reads as a rounded rect.
    final radius = BorderRadius.circular(compact ? 6 : 10);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    final body = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: child,
    );
    final pill = Material(
      color: pillColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              customBorder: shape,
              child: body,
            ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: compact
            ? [
                BoxShadow(
                  color: shadow.withValues(alpha: dark ? 0.40 : 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: shadow.withValues(alpha: dark ? 0.45 : 0.18),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: shadow.withValues(alpha: dark ? 0.28 : 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: pill,
    );
  }
}
