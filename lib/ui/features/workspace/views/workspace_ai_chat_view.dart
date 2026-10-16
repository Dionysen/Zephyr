import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/llm_chat.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_theme.dart';
import '../models/workspace_ai_context_selection.dart';
import 'workspace_ai_chat_options_sheet.dart';

/// Demo AI chat surface that replaces the plain-text editor while active.
class WorkspaceAiChatView extends StatefulWidget {
  const WorkspaceAiChatView({
    super.key,
    this.contentTopInset = 0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.contextSelection,
    this.libraryModel,
  });

  /// Clears floating chrome (e.g. mobile book bar).
  final double contentTopInset;
  final EdgeInsets contentPadding;
  final WorkspaceAiContextSelection? contextSelection;
  final LibraryViewModel? libraryModel;

  @override
  State<WorkspaceAiChatView> createState() => _WorkspaceAiChatViewState();
}

class _WorkspaceAiChatViewState extends State<WorkspaceAiChatView> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _messages = <_AiChatMessage>[];
  var _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      _messages.add(
        _AiChatMessage(
          role: _AiChatRole.assistant,
          text: context.l10n.aiChatWelcome,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    final l10n = context.l10n;
    final llm = ZephyrScope.of(context).llmSettings;
    final prior = List<_AiChatMessage>.from(_messages);
    setState(() {
      _sending = true;
      _messages.add(_AiChatMessage(role: _AiChatRole.user, text: text));
      _inputController.clear();
    });
    _scrollToEnd();
    var assistantIndex = -1;
    final expectsThinking = llm.isConfigured &&
        llm.preferences.allowThinking &&
        llm.preferences.effectiveThinkingLevel() != LlmThinkingLevel.off;
    if (llm.isConfigured &&
        (llm.preferences.streamOutput || expectsThinking)) {
      setState(() {
        _messages.add(
          _AiChatMessage(
            role: _AiChatRole.assistant,
            text: '',
            thinkingInProgress: expectsThinking,
          ),
        );
        assistantIndex = _messages.length - 1;
      });
    }
    LlmChatResult? replyResult;
    String replyText;
    try {
      if (!llm.isConfigured) {
        replyText = l10n.aiChatNotConfigured;
      } else {
        final system = await _buildContextSystemPrompt();
        final turns = <LlmChatMessage>[
          if (system.isNotEmpty)
            LlmChatMessage(role: LlmChatRole.system, text: system),
          for (final message in prior)
            if (message.role != _AiChatRole.assistant ||
                message.text != l10n.aiChatWelcome)
              LlmChatMessage(
                role: message.role == _AiChatRole.assistant
                    ? LlmChatRole.assistant
                    : LlmChatRole.user,
                text: message.text,
              ),
          LlmChatMessage(role: LlmChatRole.user, text: text),
        ];
        replyResult = await llm.completeChat(
          messages: turns,
          onPartial: assistantIndex >= 0
              ? (partial) {
                  if (!mounted) return;
                  setState(() {
                    _messages[assistantIndex] = _AiChatMessage(
                      role: _AiChatRole.assistant,
                      text: partial.text,
                      thinking: partial.thinking,
                      thinkingInProgress: partial.thinkingInProgress,
                    );
                  });
                  _scrollToEnd();
                }
              : null,
        );
        replyText = replyResult.text;
      }
    } on Object catch (error) {
      replyText = l10n.aiChatError(error.toString());
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (assistantIndex >= 0) {
        _messages[assistantIndex] = _AiChatMessage(
          role: _AiChatRole.assistant,
          text: replyText,
          thinking: replyResult?.thinking ?? '',
          thinkingInProgress: false,
        );
      } else {
        _messages.add(
          _AiChatMessage(
            role: _AiChatRole.assistant,
            text: replyText,
            thinking: replyResult?.thinking ?? '',
          ),
        );
      }
    });
    _scrollToEnd();
  }

  Future<String> _buildContextSystemPrompt() async {
    final selection = widget.contextSelection;
    final library = widget.libraryModel;
    if (selection == null || library == null) return '';
    final articles = selection.articles;
    if (articles.isEmpty) return '';
    final blocks = <String>[];
    for (final article in articles) {
      try {
        final full = await library.repository.getArticle(article.id);
        blocks.add('## ${article.title}\n\n${full.content}');
      } on Object {
        blocks.add('## ${article.title}\n\n(无法加载正文)');
      }
    }
    return '以下章节作为参考上下文：\n\n${blocks.join('\n\n---\n\n')}';
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final radius = context.zephyrCornerRadius;

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SizedBox(height: widget.contentTopInset),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: widget.contentPadding.copyWith(top: 12, bottom: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _AiChatBubble(message: message, radius: radius);
              },
            ),
          ),
          Material(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.contextSelection != null)
                      ListenableBuilder(
                        listenable: widget.contextSelection!,
                        builder: (context, _) {
                          final articles = widget.contextSelection!.articles;
                          if (articles.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final article in articles)
                                  InputChip(
                                    label: Text(
                                      article.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onDeleted: () => widget.contextSelection!
                                        .remove(article.id),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: context.l10n.aiChatInputHint,
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(radius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _sending
                          ? null
                          : () => unawaited(
                              showWorkspaceAiChatOptionsSheet(context),
                            ),
                      tooltip: context.l10n.aiChatSessionOptionsTitle,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filled(
                      onPressed: _sending ? null : () => unawaited(_send()),
                      tooltip: context.l10n.aiChatSend,
                      icon: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AiChatRole { user, assistant }

class _AiChatMessage {
  const _AiChatMessage({
    required this.role,
    required this.text,
    this.thinking = '',
    this.thinkingInProgress = false,
  });

  final _AiChatRole role;
  final String text;
  final String thinking;
  final bool thinkingInProgress;

  bool get hasThinking => thinking.trim().isNotEmpty;
}

class _AiChatBubble extends StatefulWidget {
  const _AiChatBubble({required this.message, required this.radius});

  final _AiChatMessage message;
  final double radius;

  @override
  State<_AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<_AiChatBubble> {
  var _thinkingExpanded = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isUser = message.role == _AiChatRole.user;
    final bubbleRadius = BorderRadius.circular(widget.radius.clamp(8, 20));
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final showThinkingUi = !isUser &&
        (message.thinkingInProgress || message.hasThinking);
    final thinkingLabel = message.thinkingInProgress
        ? l10n.aiChatThinkingInProgress
        : l10n.aiChatThinkingProcess;
    final bodyText = message.text.isNotEmpty
        ? message.text
        : (message.thinkingInProgress && !message.hasThinking
            ? ''
            : message.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: bubbleRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showThinkingUi) ...[
                      InkWell(
                        onTap: () => setState(
                          () => _thinkingExpanded = !_thinkingExpanded,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.thinkingInProgress)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: fg.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              Text(
                                thinkingLabel,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: fg.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _thinkingExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
                                color: fg.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_thinkingExpanded && message.hasThinking) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          message.thinking,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else if (message.thinkingInProgress &&
                          message.hasThinking &&
                          !_thinkingExpanded) ...[
                        const SizedBox(height: 4),
                      ],
                    ],
                    if (bodyText.isNotEmpty)
                      SelectableText(
                        bodyText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fg,
                          height: 1.45,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
