import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../domain/models/llm_chat.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_markdown_body.dart';
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
  final _liveAssistant = ValueNotifier<_StreamAssistantFrame?>(null);
  var _liveAssistantMessageIndex = -1;
  var _sending = false;

  /// Finger is on the list and dragging (hold-scroll); blocks stream pin jumps.
  var _userInteractingWithScroll = false;

  /// Invalidates queued [addPostFrameCallback] pin scrolls when the user drags.
  var _scrollPinEpoch = 0;

  static const _followSlop = 72.0;

  bool _handleListScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userInteractingWithScroll = true;
      _scrollPinEpoch++;
    } else if (notification is UserScrollNotification) {
      _userInteractingWithScroll =
          notification.direction != ScrollDirection.idle;
    } else if (notification is ScrollEndNotification) {
      _userInteractingWithScroll = false;
    }
    return false;
  }

  bool _canPinStreamTail({bool force = false}) {
    if (force) return true;
    if (_userInteractingWithScroll) return false;
    return _isNearListBottom();
  }

  bool _isNearListBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - _followSlop;
  }

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
    _liveAssistant.dispose();
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
    _scrollToEnd(animate: true, force: true);
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
        _liveAssistantMessageIndex = assistantIndex;
        _liveAssistant.value = _StreamAssistantFrame(
          text: '',
          thinking: '',
          thinkingInProgress: expectsThinking,
        );
      });
      _scrollToEnd(animate: false, force: true);
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
                  _liveAssistant.value = _StreamAssistantFrame(
                    text: partial.text,
                    thinking: partial.thinking,
                    thinkingInProgress: partial.thinkingInProgress,
                  );
                  _scrollToEndIfPinned();
                }
              : null,
        );
        replyText = replyResult.text;
      }
    } on Object catch (error) {
      replyText = l10n.aiChatError(error.toString());
    }
    if (!mounted) return;
    _liveAssistantMessageIndex = -1;
    _liveAssistant.value = null;
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
    _scrollToEndIfPinned();
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

  /// During streaming: scroll only while the user is already at the list bottom.
  void _scrollToEndIfPinned() {
    final epoch = _scrollPinEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _scrollPinEpoch) return;
      _scrollToEndNow(animate: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || epoch != _scrollPinEpoch) return;
        _scrollToEndNow(animate: false);
      });
    });
  }

  void _scrollToEnd({bool animate = false, bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToEndNow(animate: animate, force: force);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToEndNow(animate: false, force: force);
      });
    });
  }

  void _scrollToEndNow({required bool animate, bool force = false}) {
    if (!_canPinStreamTail(force: force)) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = position.maxScrollExtent;
    if (animate) {
      unawaited(
        position.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }
    if (position.pixels != target) {
      position.jumpTo(target);
    }
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
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleListScrollNotification,
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: widget.contentPadding.copyWith(top: 12, bottom: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  if (index == _liveAssistantMessageIndex) {
                    return ValueListenableBuilder<_StreamAssistantFrame?>(
                      valueListenable: _liveAssistant,
                      builder: (context, frame, _) {
                        final base = _messages[index];
                        final message = frame == null
                            ? base
                            : _AiChatMessage(
                                role: _AiChatRole.assistant,
                                text: frame.text,
                                thinking: frame.thinking,
                                thinkingInProgress: frame.thinkingInProgress,
                              );
                        return _AiChatBubble(
                          message: message,
                          radius: radius,
                          markdownLiveStream: frame != null,
                        );
                      },
                    );
                  }
                  final message = _messages[index];
                  return _AiChatBubble(
                    key: ValueKey('chat-msg-$index'),
                    message: message,
                    radius: radius,
                  );
                },
              ),
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

class _StreamAssistantFrame {
  const _StreamAssistantFrame({
    required this.text,
    required this.thinking,
    required this.thinkingInProgress,
  });

  final String text;
  final String thinking;
  final bool thinkingInProgress;
}

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
  const _AiChatBubble({
    super.key,
    required this.message,
    required this.radius,
    this.markdownLiveStream = false,
  });

  final _AiChatMessage message;
  final double radius;
  final bool markdownLiveStream;

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
            child: RepaintBoundary(
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
                        ZephyrMarkdownBody(
                          data: message.thinking,
                          foreground: fg.withValues(alpha: 0.75),
                          baseStyle: theme.textTheme.bodySmall?.copyWith(
                            color: fg.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                          dense: true,
                          liveStream: widget.markdownLiveStream,
                        ),
                        const SizedBox(height: 8),
                      ] else if (message.thinkingInProgress &&
                          message.hasThinking &&
                          !_thinkingExpanded) ...[
                        const SizedBox(height: 4),
                      ],
                    ],
                    if (bodyText.isNotEmpty)
                      isUser
                          ? SelectableText(
                              bodyText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: fg,
                                height: 1.45,
                              ),
                            )
                          : ZephyrMarkdownBody(
                              data: bodyText,
                              foreground: fg,
                              baseStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: fg,
                                height: 1.45,
                              ),
                              liveStream: widget.markdownLiveStream,
                            ),
                  ],
                ),
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
