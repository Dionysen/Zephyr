import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../../../domain/use_cases/paragraph_indentation.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../../editor/view_models/library_view_model.dart';
import 'paragraph_indent_editing.dart';
import 'plain_text_document.dart';

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
  final _editListener = _ContentEditListener();

  Editor? _editor;
  String? _articleId;
  int? _indent;
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    _editListener.onChanged = _onDocumentEdited;
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
    _tearDownEditor();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _tearDownEditor() {
    final editor = _editor;
    if (editor == null) return;
    editor.removeListener(_editListener);
    editor.dispose();
    _editor = null;
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
      _tearDownEditor();
      return;
    }
    if (article.id == _articleId && _editor != null) return;

    _articleId = article.id;
    _indent = widget.preferences.preferences.firstLineIndent;
    final content = applyParagraphIndentation(article.content, _indent!);
    _lastEmitted = content;
    _rebuildEditor(content);
  }

  void _rebuildEditor(String content) {
    _tearDownEditor();
    final document = documentFromPlainText(content);
    final editor = createZephyrDocumentEditor(document: document);
    editor.addListener(_editListener);
    _editor = editor;
  }

  void _applyIndent(int indent) {
    _indent = indent;
    final editor = _editor;
    if (editor == null) return;
    final formatted = applyParagraphIndentation(
      plainTextFromDocument(editor.document),
      indent,
    );
    if (formatted == _lastEmitted) {
      setState(() {});
      return;
    }
    _lastEmitted = formatted;
    _rebuildEditor(formatted);
    setState(() {});
    widget.model.updateContent(formatted);
  }

  void _onDocumentEdited(List<EditEvent> changeList) {
    final editor = _editor;
    if (editor == null || widget.model.isReadOnly) return;
    if (changeList.isEmpty) return;

    // Preserve per-paragraph indent from Enter/Tab editing; preference changes
    // still reformat through [_applyIndent].
    final plain = plainTextFromDocument(editor.document);
    if (plain == _lastEmitted) return;
    _lastEmitted = plain;
    widget.model.updateContent(plain);
  }

  Stylesheet _stylesheet(BuildContext context, double horizontalPadding) {
    final preferences = widget.preferences.preferences;
    final color = Theme.of(context).colorScheme.onSurface;
    final gap = preferences.fontSize * preferences.paragraphSpacing;
    return Stylesheet(
      documentPadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        28,
        horizontalPadding,
        48,
      ),
      inlineTextStyler: defaultInlineTextStyler,
      inlineWidgetBuilders: defaultInlineWidgetBuilderChain,
      rules: [
        StyleRule(BlockSelector.all, (doc, node) {
          return {
            Styles.maxWidth: preferences.maxContentWidth,
            Styles.textStyle: TextStyle(
              color: color,
              fontSize: preferences.fontSize,
              height: preferences.lineHeight,
              fontFamily: preferences.fontFamily,
            ),
          };
        }),
        StyleRule(const BlockSelector('paragraph'), (doc, node) {
          final index = doc.getNodeIndexById(node.id);
          return {
            Styles.padding: CascadingPadding.only(top: index <= 0 ? 0 : gap),
          };
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.model.article;
    final editor = _editor;
    if (article == null || editor == null) {
      return const Center(
        child: Text('Choose or create a chapter to begin writing.'),
      );
    }
    final preferences = widget.preferences.preferences;
    final theme = Theme.of(context);
    final selectionColor = theme.colorScheme.primary.withValues(alpha: 0.35);
    final cursorColor =
        theme.textSelectionTheme.cursorColor ?? theme.colorScheme.onSurface;
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal =
                    ((constraints.maxWidth - preferences.maxContentWidth) / 2)
                        .clamp(42.0, double.infinity);
                final stylesheet = _stylesheet(context, horizontal);
                final selectionStyle = SelectionStyles(
                  selectionColor: selectionColor,
                );
                final documentOverlays = [
                  const SuperEditorIosToolbarFocalPointDocumentLayerBuilder(),
                  SuperEditorIosHandlesDocumentLayerBuilder(
                    handleColor: cursorColor,
                  ),
                  const SuperEditorAndroidToolbarFocalPointDocumentLayerBuilder(),
                  SuperEditorAndroidHandlesDocumentLayerBuilder(
                    caretColor: cursorColor,
                  ),
                  DefaultCaretOverlayBuilder(
                    caretStyle: CaretStyle(width: 2, color: cursorColor),
                  ),
                ];
                final child = widget.model.isReadOnly
                    ? SuperReader(
                        editor: editor,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        stylesheet: stylesheet,
                        selectionStyle: selectionStyle,
                      )
                    : SuperEditor(
                        editor: editor,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        stylesheet: stylesheet,
                        selectionStyle: selectionStyle,
                        documentOverlayBuilders: documentOverlays,
                        androidHandleColor: cursorColor,
                        iOSHandleColor: cursorColor,
                        keyboardActions: [
                          tabToInsertFirstLineIndent(
                            () => widget.preferences.preferences.firstLineIndent,
                          ),
                          ...defaultImeKeyboardActions,
                        ],
                        contentTapDelegateFactories: const [],
                      );
                return Scrollbar(
                  controller: _scrollController,
                  child: child,
                );
              },
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: IgnorePointer(
              child: Text(
                '${article.content.runes.length} characters',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentEditListener implements EditListener {
  void Function(List<EditEvent> changeList)? onChanged;

  @override
  void onEdit(List<EditEvent> changeList) => onChanged?.call(changeList);
}
