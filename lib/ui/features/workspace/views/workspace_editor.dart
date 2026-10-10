import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/editor_margins.dart';
import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/use_cases/paired_punctuation.dart';
import '../../../../domain/use_cases/paragraph_indentation.dart';
import '../../editor/plain_text/decoration/text_decoration_model.dart';
import '../../editor/plain_text/input/plain_text_editing_controller.dart';
import '../../editor/plain_text/layout/editor_typography.dart';
import '../../editor/plain_text/zephyr_plain_text_editor.dart';
import '../../editor/quick_toolbar/quick_toolbar_host.dart';
import '../../editor/quick_toolbar/workspace_editor_bridge.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';

class WorkspaceEditor extends StatefulWidget {
  const WorkspaceEditor({
    super.key,
    required this.model,
    required this.preferences,
    this.contentTopInset = 0,
    this.showWordCount = true,
    this.bridge,
  });

  final LibraryViewModel model;
  final EditorPreferencesViewModel preferences;

  /// Extra top padding so content clears a floating overlay (e.g. mobile book bar).
  final double contentTopInset;

  /// When false, the host (e.g. mobile chrome) owns the word-count capsule.
  final bool showWordCount;

  /// Optional bridge for the compact IME quick toolbar.
  final WorkspaceEditorBridge? bridge;

  @override
  State<WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _WorkspaceEditorState extends State<WorkspaceEditor> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  final _controller = PlainTextEditingController();
  final _titleController = TextEditingController();
  final _editorKey = GlobalKey<ZephyrPlainTextEditorState>();

  /// Last caret per article for the current editor session.
  final Map<String, TextSelection> _carets = {};

  /// Last scroll offset per article for the current editor session.
  final Map<String, double> _scrolls = {};

  String? _articleId;
  int? _indent;
  String _lastEmitted = '';
  String _pairTrackText = '';
  PairedPunctuationSession? _pairSession;
  var _suppressAutoPair = false;
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
    _controller.addListener(_syncBridge);
    _titleController.addListener(_onTitleChanged);
    _titleFocusNode.addListener(_onTitleFocusChanged);
    _focusNode.addListener(_syncBridge);
    _scrollController.addListener(_onScrollForJumpChip);
    _syncFromModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBridge());
  }

  @override
  void didUpdateWidget(WorkspaceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      oldWidget.preferences.removeListener(_onPreferences);
      widget.preferences.addListener(_onPreferences);
    }
    if (oldWidget.bridge != widget.bridge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncBridge());
    }
    _syncFromModel();
  }

  @override
  void dispose() {
    _persistEditorPosition();
    widget.preferences.removeListener(_onPreferences);
    _controller.removeListener(_onControllerChanged);
    _controller.removeListener(_syncBridge);
    _titleController.removeListener(_onTitleChanged);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _focusNode.removeListener(_syncBridge);
    _scrollController.removeListener(_onScrollForJumpChip);
    _controller.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _syncBridge() {
    final bridge = widget.bridge;
    if (bridge == null) return;
    bridge.bind(
      controller: _controller,
      editor: _editorKey.currentState,
      focusNode: _focusNode,
      bodyFocused: _focusNode.hasPrimaryFocus,
      firstLineIndent: widget.preferences.preferences.firstLineIndent,
      insertPhrase: _insertPhraseOrPair,
    );
  }

  void _insertPhraseOrPair(String text) {
    final pair = resolvePairedPunctuationInsert(text);
    if (pair == null) {
      _controller.insertText(text, coalesce: false);
      return;
    }
    _beginPairSession(
      pair: pair,
      openIndex: _controller.selection.start,
      insertFullPair: true,
    );
  }

  void _beginPairSession({
    required PairedPunctuationInsert pair,
    required int openIndex,
    required bool insertFullPair,
  }) {
    _suppressAutoPair = true;
    try {
      final openEnd = openIndex + pair.open.length;
      if (insertFullPair) {
        _controller.replaceSelection(pair.text, coalesce: false);
      } else {
        // Opener already present from typing; append closer after it.
        _controller.setSelection(TextSelection.collapsed(offset: openEnd));
        _controller.insertText(pair.close, coalesce: false);
      }
      // Pin caret between glyphs after the text is final.
      _controller.setSelection(TextSelection.collapsed(offset: openEnd));
      _pairTrackText = _controller.text;
      _pairSession = PairedPunctuationSession(
        openIndex: openIndex,
        closeIndex: openEnd,
        openChar: pair.open,
        closeChar: pair.close,
      );
      _armPairSelectionSnap();
      _editorKey.currentState?.lockPairCaret(
        openIndex: openIndex,
        caret: openEnd,
        highlightEnd: openEnd + pair.close.length,
      );
      setState(() {});
    } finally {
      _suppressAutoPair = false;
    }
  }

  /// Keyboard / IME typed an opener (or a full pair) — same wrap as toolbar.
  ///
  /// The IME client expands a lone opener to a full pair in the same edit;
  /// here we only activate the one-shot highlight session (synchronously).
  bool _maybeAutoPairTypedOpener() {
    if (_suppressAutoPair || _pairSession != null) return false;
    final before = _pairTrackText;
    final after = _controller.text;
    final typed = detectTypedPairedPunctuation(before: before, after: after);
    if (typed == null) return false;

    final pair = typed.pair;
    final openIndex = typed.openIndex;
    if (typed.needsCloser) {
      // Fallback when a non-IME path inserted only the opener.
      _beginPairSession(
        pair: pair,
        openIndex: openIndex,
        insertFullPair: false,
      );
      return true;
    }

    final openEnd = openIndex + pair.open.length;
    _suppressAutoPair = true;
    try {
      if (_controller.selection.extentOffset != openEnd ||
          !_controller.selection.isCollapsed) {
        _controller.setSelection(TextSelection.collapsed(offset: openEnd));
      }
      _pairTrackText = _controller.text;
      _pairSession = PairedPunctuationSession(
        openIndex: openIndex,
        closeIndex: openEnd,
        openChar: pair.open,
        closeChar: pair.close,
      );
      _armPairSelectionSnap();
      _editorKey.currentState?.lockPairCaret(
        openIndex: openIndex,
        caret: openEnd,
        highlightEnd: openEnd + pair.close.length,
      );
      setState(() {});
    } finally {
      _suppressAutoPair = false;
    }
    return true;
  }

  /// While set, IME selection echoes onto the pair glyphs snap back instead
  /// of ending the wrap session. Cleared after a short window / real exit.
  int _pairSnapUntilMs = 0;

  void _armPairSelectionSnap() {
    _pairSnapUntilMs = DateTime.now().millisecondsSinceEpoch + 600;
  }

  void _maybeExitPairSessionForSelection(TextSelection selection) {
    if (_suppressAutoPair) return;
    final session = _pairSession;
    if (session == null) return;
    if (!session.matches(_controller.text)) {
      _clearPairSession();
      return;
    }
    if (session.containsSelection(selection)) return;
    // Right after insert, Chinese IMEs often yank the caret onto the opener;
    // snap back for a brief window, then treat any leave as a real exit.
    final snapping =
        DateTime.now().millisecondsSinceEpoch <= _pairSnapUntilMs;
    if (snapping &&
        selection.isCollapsed &&
        selection.extentOffset >= session.openIndex &&
        selection.extentOffset <= session.highlightEnd) {
      _suppressAutoPair = true;
      try {
        _controller.setSelection(
          TextSelection.collapsed(offset: session.interiorStart),
        );
      } finally {
        _suppressAutoPair = false;
      }
      return;
    }
    _pairSnapUntilMs = 0;
    _clearPairSession();
  }

  bool _consumePairNewline() {
    final session = _pairSession;
    if (session == null || !session.matches(_controller.text)) {
      _clearPairSession();
      return false;
    }
    _controller.setSelection(
      TextSelection.collapsed(offset: session.highlightEnd),
    );
    _clearPairSession();
    return true;
  }

  void _clearPairSession() {
    if (_pairSession == null) return;
    setState(() => _pairSession = null);
  }

  void _remapPairSession() {
    final text = _controller.text;
    if (_suppressAutoPair) {
      _pairTrackText = text;
      return;
    }
    final session = _pairSession;
    if (session == null) {
      _pairTrackText = text;
      return;
    }
    if (text == _pairTrackText) return;
    final before = _pairTrackText;
    final next = remapPairedPunctuationSession(session, before, text);
    if (next == null) {
      final orphan = orphanCloserRangeAfterEmptyOpenDeleted(
        session: session,
        before: before,
        after: text,
      );
      _pairSession = null;
      _pairTrackText = text;
      setState(() {});
      if (orphan != null) {
        // Defer: cannot mutate the controller during its notify cycle.
        final start = orphan.start;
        final end = orphan.end;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _pairSession != null) return;
          final current = _controller.text;
          if (end > current.length ||
              current.substring(start, end) != session.closeChar) {
            return;
          }
          _controller.setSelection(
            TextSelection(baseOffset: start, extentOffset: end),
          );
          _controller.replaceSelection('', coalesce: false);
          _pairTrackText = _controller.text;
        });
      }
      return;
    }
    _pairTrackText = text;
    if (next.openIndex != session.openIndex ||
        next.closeIndex != session.closeIndex) {
      setState(() => _pairSession = next);
    } else {
      _pairSession = next;
    }
  }

  List<TextSpanDecoration> _pairDecorations(BuildContext context) {
    final session = _pairSession;
    if (session == null || !session.matches(_controller.text)) {
      return const [];
    }
    final accent = Theme.of(context).colorScheme.primary;
    final fontSize = widget.preferences.preferences.fontSize;
    // Frame only the interior text; keep a caret-sized slot when empty.
    return [
      TextSpanDecoration(
        start: session.interiorStart,
        end: session.interiorEnd,
        background: accent.withValues(alpha: 0.22),
        borderColor: accent.withValues(alpha: 0.40),
        borderWidth: 1.5,
        borderRadius: 8,
        edgeInflate: const EdgeInsets.fromLTRB(2, 3, 2, 3),
        minEmptyWidth: (fontSize * 0.12).clamp(2.0, 4.0),
        emptyAnchorStart: session.openIndex,
        emptyAnchorEnd: session.highlightEnd,
      ),
    ];
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

  /// Offer the chip when the document end is still off-screen.
  ///
  /// [ignoreCaret]: used on chapter open — restored/default caret is often at
  /// EOF even when the viewport is still at the top; only hide for caret-at-end
  /// after the user moves the selection.
  bool _isImeVisible() {
    if (!mounted) return false;
    return MediaQuery.viewInsetsOf(context).bottom > 0.5;
  }

  bool _shouldOfferJumpToEnd({
    TextSelection? selection,
    bool ignoreCaret = false,
  }) {
    if (_controller.text.isEmpty) return false;
    if (_isImeVisible()) return false;
    if (_isScrollAtEnd()) return false;
    if (!ignoreCaret) {
      final sel = selection ?? _controller.selection;
      // No text after the caret / selection end.
      if (sel.end >= _controller.text.length) return false;
    }
    return true;
  }

  void _syncJumpToEndVisibility({
    TextSelection? selection,
    bool ignoreCaret = false,
  }) {
    final show = _shouldOfferJumpToEnd(
      selection: selection,
      ignoreCaret: ignoreCaret,
    );
    if (show == _showJumpToEnd) return;
    setState(() => _showJumpToEnd = show);
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
    _maybeExitPairSessionForSelection(selection);
    if (_showJumpToEnd &&
        !_shouldOfferJumpToEnd(selection: selection)) {
      _dismissJumpToEnd();
    }
  }

  void _syncFromModel() {
    final article = widget.model.article;
    if (article == null) {
      _persistEditorPosition();
      _articleId = null;
      _pairSession = null;
      _pairTrackText = '';
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
    if (switching) {
      _pairSession = null;
      _pairTrackText = '';
    }

    final keepSelection = switching
        ? _carets[article.id]
        : _controller.selection;
    _articleId = article.id;
    _lastEmitted = content;
    _suppressControllerNotify = true;
    _controller.setText(content, selection: keepSelection);
    _suppressControllerNotify = false;
    if (!switching) {
      _pairTrackText = _controller.text;
    } else {
      _pairTrackText = content;
    }

    if (switching) {
      // Decide after layout: show when the chapter opens away from the end.
      // Ignore caret here — setText defaults / restored carets are often at EOF.
      _showJumpToEnd = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _articleId != article.id) return;
        _restoreScroll(article.id);
        if (!_scrollController.hasClients) return;
        _lastJumpScroll = _scrollController.offset;
        _syncJumpToEndVisibility(ignoreCaret: true);
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
    if (!_suppressAutoPair) {
      _maybeAutoPairTypedOpener();
    }
    _remapPairSession();
    _maybeExitPairSessionForSelection(_controller.selection);
    if (_showJumpToEnd && !_shouldOfferJumpToEnd()) {
      _dismissJumpToEnd();
    }
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

  EditorTypography _typography(BuildContext context, EditorPreferences prefs) {
    final color = Theme.of(context).colorScheme.onSurface;
    // Title block owns the top inset; body only needs a short gap below it.
    return EditorTypography(
      color: color,
      fontSize: prefs.fontSize,
      fontFamily: prefs.fontFamily,
      lineHeight: prefs.lineHeight,
      paragraphSpacing: prefs.paragraphSpacing,
      marginLeft: prefs.marginLeft,
      marginRight: prefs.marginRight,
      firstLineIndent: prefs.firstLineIndent,
      paddingTop: 12,
      paddingBottom: 48,
    );
  }

  Widget _titleHeader(BuildContext context, EditorPreferences prefs) {
    final theme = Theme.of(context);
    final top = 20 + widget.contentTopInset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final margins = EditorMargins.resolve(
          viewportWidth: constraints.maxWidth,
          desiredLeft: prefs.marginLeft,
          desiredRight: prefs.marginRight,
          minContentWidth: math.max(120.0, prefs.fontSize * 8),
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(margins.left, top, margins.right, 0),
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
                  hintText: context.l10n.untitled,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.model.article;
    if (article == null) {
      return Center(child: Text(context.l10n.editorEmptyState));
    }

    final preferences = widget.preferences.preferences;
    final theme = Theme.of(context);
    final selectionColor = theme.colorScheme.primary.withValues(alpha: 0.35);
    final cursorColor =
        theme.textSelectionTheme.cursorColor ?? theme.colorScheme.onSurface;
    final typography = _typography(context, preferences);
    // viewPadding keeps the gesture-bar height after edge-to-edge removePadding.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showJump = _showJumpToEnd && keyboardInset <= 0.5;
    if (_showJumpToEnd && keyboardInset > 0.5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dismissJumpToEnd();
      });
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: ZephyrPlainTextEditor(
              key: _editorKey,
              controller: _controller,
              typography: typography,
              scrollController: _scrollController,
              focusNode: _focusNode,
              readOnly: widget.model.isReadOnly,
              cursorColor: cursorColor,
              selectionColor: selectionColor,
              decorations: _pairDecorations(context),
              header: _titleHeader(context, preferences),
              scrollbarPadding: EdgeInsets.symmetric(
                vertical: widget.contentTopInset,
              ),
              bottomObstruction: quickToolbarBottomObstructionOf(context),
              consumeNewline: _consumePairNewline,
              shortcuts: ZephyrScope.of(context).keyboardShortcuts,
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
        if (showJump)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 + bottomInset + keyboardInset,
            child: Center(
              child: EditorOverlayCapsule(
                onTap: _jumpToEnd,
                child: Text(
                  context.l10n.jumpToEnd,
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
