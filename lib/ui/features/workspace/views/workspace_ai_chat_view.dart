import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_theme.dart';
import '../models/workspace_ai_context_selection.dart';

/// Demo AI chat surface that replaces the plain-text editor while active.
class WorkspaceAiChatView extends StatefulWidget {
  const WorkspaceAiChatView({
    super.key,
    this.contentTopInset = 0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.contextSelection,
  });

  /// Clears floating chrome (e.g. mobile book bar).
  final double contentTopInset;
  final EdgeInsets contentPadding;
  final WorkspaceAiContextSelection? contextSelection;

  @override
  State<WorkspaceAiChatView> createState() => _WorkspaceAiChatViewState();
}

class _WorkspaceAiChatViewState extends State<WorkspaceAiChatView> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _messages = <_AiChatMessage>[];

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

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_AiChatMessage(role: _AiChatRole.user, text: text));
      _messages.add(
        _AiChatMessage(
          role: _AiChatRole.assistant,
          text: context.l10n.aiChatDemoReply(text),
        ),
      );
      _inputController.clear();
    });
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
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _send,
                      tooltip: context.l10n.aiChatSend,
                      icon: const Icon(Icons.arrow_upward_rounded),
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
  const _AiChatMessage({required this.role, required this.text});

  final _AiChatRole role;
  final String text;
}

class _AiChatBubble extends StatelessWidget {
  const _AiChatBubble({required this.message, required this.radius});

  final _AiChatMessage message;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == _AiChatRole.user;
    final bubbleRadius = BorderRadius.circular(radius.clamp(8, 20));
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

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
                child: Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    height: 1.45,
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
