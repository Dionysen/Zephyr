import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/ai_chat_session.dart'
    show AiChatMessageRole, AiChatStoredMessage, kAiChatNewConversation;
import '../../../../domain/models/llm_chat.dart';
import '../../../../domain/llm/llm_provider_catalog.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../../../domain/repositories/writing_library_repository.dart';
import '../../../../domain/use_cases/ai_chat_context_compression.dart';
import '../../editor/plain_text/zephyr_editor_scrollbar.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../../core/zephyr_chat_bubble_shape.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_markdown_body.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../models/ai_stream_reveal.dart';
import '../models/workspace_ai_composer_document.dart';
import '../models/workspace_ai_context_selection.dart';
import 'workspace_ai_chat_composer_field.dart';
import 'workspace_ai_chat_options_sheet.dart';
import 'workspace_ai_sessions_sheet.dart';

/// Keeps [TextField] IME active when tapping other controls in the composer.
final Object _aiChatComposerTapGroup = Object();

/// Keeps the latest bubble pinned while its height changes, in the same layout
/// pass, so the bottom does not grow and then jump on the next frame.
class _AiChatTailScrollController extends ScrollController {
  bool Function() followTail = () => false;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _AiChatTailScrollPosition(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      followTail: () => followTail(),
    );
  }
}

class _AiChatTailScrollPosition extends ScrollPositionWithSingleContext {
  _AiChatTailScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.followTail,
  });

  final bool Function() followTail;

  @override
  bool correctForNewDimensions(
    ScrollMetrics oldPosition,
    ScrollMetrics newPosition,
  ) {
    final distanceFromEnd = oldPosition.maxScrollExtent - oldPosition.pixels;
    // A thumb drag jumpTo runs before this correction, while [oldPosition]
    // can still be the pre-jump metrics parked at the end. Only keep the tail
    // when the live offset has not moved away from that end.
    final pixelsUnchanged = (pixels - oldPosition.pixels).abs() <= 1;
    final stick = followTail() && distanceFromEnd <= 1 && pixelsUnchanged;
    if (!stick) {
      return super.correctForNewDimensions(oldPosition, newPosition);
    }
    final target = newPosition.maxScrollExtent;
    if ((target - pixels).abs() <= 0.5) return true;
    correctPixels(target);
    return false;
  }
}

/// Demo AI chat surface that replaces the plain-text editor while active.
class WorkspaceAiChatView extends StatefulWidget {
  const WorkspaceAiChatView({
    super.key,
    this.contentTopInset = 0,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.bleedEditorBackground = false,
    this.contextSelection,
    this.libraryModel,
  });

  /// Clears floating chrome (e.g. mobile book bar).
  final double contentTopInset;

  /// When true, the list area is transparent so a parent [EditorBackgroundLayer]
  /// can show through (immersive mobile chrome). Top chrome clearance is applied
  /// as scroll padding so messages can still move under the status band.
  final bool bleedEditorBackground;
  final EdgeInsets contentPadding;
  final WorkspaceAiContextSelection? contextSelection;
  final LibraryViewModel? libraryModel;

  @override
  State<WorkspaceAiChatView> createState() => _WorkspaceAiChatViewState();
}

class _WorkspaceAiChatViewState extends State<WorkspaceAiChatView>
    with WidgetsBindingObserver {
  final _scrollController = _AiChatTailScrollController();
  late final WorkspaceAiComposerController _composer;
  final _messages = <_AiChatMessage>[];
  final _liveAssistant = ValueNotifier<_StreamAssistantFrame?>(null);
  var _liveAssistantMessageIndex = -1;
  var _sending = false;
  String? _sessionId;
  String? _boundArticleId;
  var _loadingSession = false;
  String _contextSummary = '';

  /// Finger is on the list and dragging (hold-scroll); blocks tail anchoring.
  var _userInteractingWithScroll = false;

  var _drawerDragBlockedForList = false;

  /// Composer card height, excluding the soft keyboard.
  ///
  /// The keyboard is added from [MediaQuery.viewInsets] on each build so the
  /// list padding and scrollbar track match the IME in the same frame.
  var _composerOverlayHeight = 112.0;

  Timer? _scrollSaveDebounce;
  final _streamReveal = AiStreamReveal();
  Timer? _revealTimer;
  var _restoringScroll = false;
  var _scrollRestoreEpoch = 0;

  /// List stays invisible while a remembered offset is applied, so the
  /// lazy list's frame-by-frame jump is never painted.
  var _holdListUntilScrollRestored = false;

  static const _followSlop = 72.0;

  void _setDrawerDragBlockedForList(bool blocked) {
    if (_drawerDragBlockedForList == blocked) return;
    _drawerDragBlockedForList = blocked;
    if (!mounted) return;
    ZephyrDrawerDragBlockNotification(blocked: blocked).dispatch(context);
  }

  bool _handleListScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userInteractingWithScroll = true;
      _setDrawerDragBlockedForList(true);
    } else if (notification is UserScrollNotification) {
      _userInteractingWithScroll =
          notification.direction != ScrollDirection.idle;
      _setDrawerDragBlockedForList(
        notification.direction != ScrollDirection.idle,
      );
    } else if (notification is ScrollEndNotification) {
      _userInteractingWithScroll = false;
      _setDrawerDragBlockedForList(false);
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
  void initState() {
    super.initState();
    _composer = WorkspaceAiComposerController();
    _scrollController.followTail = () =>
        !_restoringScroll && !_userInteractingWithScroll;
    _composer.onTextFocusChanged = () {
      if (!mounted) return;
      _scrollToEnd(force: true);
    };
    widget.contextSelection?.attachComposer(_composer);
    _scrollController.addListener(_onListScrollOffsetChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bindArticle(_currentArticleId()));
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!_composer.hasTextFocus() || !mounted) return;
    _scrollToEnd(force: true);
  }

  @override
  void didUpdateWidget(covariant WorkspaceAiChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextSelection != widget.contextSelection) {
      oldWidget.contextSelection?.detachComposer(_composer);
      widget.contextSelection?.attachComposer(_composer);
    }
    final articleId = _currentArticleId();
    if (articleId != _boundArticleId) {
      unawaited(_bindArticle(articleId));
    }
  }

  String? _currentArticleId() => widget.libraryModel?.article?.id;

  WritingLibraryRepository? _repository() => widget.libraryModel?.repository;

  Future<void> _bindArticle(String? articleId) async {
    if (articleId == _boundArticleId && !_loadingSession) return;
    await _persistScrollOffset();
    _boundArticleId = articleId;
    final repo = _repository();
    if (articleId == null || repo == null) {
      if (!mounted) return;
      setState(() {
        _sessionId = null;
        _contextSummary = '';
        _holdListUntilScrollRestored = false;
        _messages.clear();
        _seedWelcomeIfEmpty();
      });
      return;
    }
    setState(() => _loadingSession = true);
    try {
      final session = await repo.loadActiveAiChatSession(articleId);
      final stored = session == null
          ? <AiChatStoredMessage>[]
          : await repo.listAiChatMessages(session.id);
      final scrollOffset = await repo.loadAiChatScrollOffset(
        articleId: articleId,
        sessionId: session?.id,
      );
      if (!mounted || _boundArticleId != articleId) return;
      final pendingOffset = scrollOffset != null && scrollOffset > 0
          ? scrollOffset
          : null;
      setState(() {
        _sessionId = session?.id;
        _contextSummary = session?.contextSummary ?? '';
        _loadingSession = false;
        _holdListUntilScrollRestored = pendingOffset != null;
        _messages
          ..clear()
          ..addAll(stored.map(_messageFromStored));
        _seedWelcomeIfEmpty();
      });
      if (pendingOffset != null) {
        _restoreScrollOffset(pendingOffset);
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingSession = false;
        _holdListUntilScrollRestored = false;
      });
    }
  }

  void _onListScrollOffsetChanged() {
    if (_restoringScroll || !_scrollController.hasClients) return;
    _scrollSaveDebounce?.cancel();
    _scrollSaveDebounce = Timer(const Duration(milliseconds: 280), () {
      unawaited(_persistScrollOffset());
    });
  }

  Future<void> _persistScrollOffset() async {
    final articleId = _boundArticleId;
    final repo = _repository();
    if (articleId == null || repo == null || !_scrollController.hasClients) {
      return;
    }
    final pixels = _scrollController.offset;
    await repo.saveAiChatScrollOffset(
      articleId: articleId,
      sessionId: _sessionId,
      offset: pixels,
    );
  }

  void _revealMessageList() {
    if (!_holdListUntilScrollRestored || !mounted) return;
    setState(() => _holdListUntilScrollRestored = false);
  }

  void _restoreScrollOffset(double offset) {
    _restoringScroll = true;
    final epoch = ++_scrollRestoreEpoch;
    var attempts = 0;
    double? previousMax;
    void finish() {
      if (!mounted || epoch != _scrollRestoreEpoch) return;
      _restoringScroll = false;
      _revealMessageList();
    }

    void attempt() {
      if (!mounted || epoch != _scrollRestoreEpoch) return;
      if (!_scrollController.hasClients) {
        if (attempts++ < 24) {
          WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
        } else {
          finish();
        }
        return;
      }
      final position = _scrollController.position;
      final max = position.maxScrollExtent;
      final target = offset.clamp(0.0, max);
      if ((position.pixels - target).abs() > 0.5) {
        position.jumpTo(target);
      }
      final settled = previousMax != null && (max - previousMax!).abs() < 0.5;
      previousMax = max;
      final stillShort = max + 1 < offset;
      if ((!settled || stillShort) && attempts++ < 24) {
        WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
        return;
      }
      finish();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  Future<void> openSessionsSheet() async {
    final articleId = _currentArticleId();
    final repo = _repository();
    if (articleId == null || repo == null) return;
    final selected = await showWorkspaceAiSessionsSheet(
      context,
      repository: repo,
      articleId: articleId,
      activeSessionId: _sessionId,
    );
    if (selected == null || !mounted) return;
    if (selected == kAiChatNewConversation) {
      await repo.beginNewAiChatConversation(articleId);
    } else {
      await repo.setActiveAiChatSession(
        articleId: articleId,
        sessionId: selected,
      );
    }
    _boundArticleId = null;
    await _bindArticle(articleId);
  }

  Future<String?> _ensurePersistedSessionId() async {
    if (_sessionId != null) return _sessionId;
    final articleId = _currentArticleId();
    final repo = _repository();
    if (articleId == null || repo == null) return null;
    final session = await repo.createAiChatSession(articleId: articleId);
    await repo.setActiveAiChatSession(
      articleId: articleId,
      sessionId: session.id,
    );
    _sessionId = session.id;
    _contextSummary = session.contextSummary;
    return session.id;
  }

  void _seedWelcomeIfEmpty() {
    if (_messages.isNotEmpty) return;
    _messages.add(
      _AiChatMessage(
        role: _AiChatRole.assistant,
        text: context.l10n.aiChatWelcome,
      ),
    );
  }

  _AiChatMessage _messageFromStored(AiChatStoredMessage message) =>
      _AiChatMessage(
        storageId: message.id,
        role: message.role == AiChatMessageRole.user
            ? _AiChatRole.user
            : _AiChatRole.assistant,
        text: message.body,
        modelText: message.modelBody,
        thinking: message.thinking,
      );

  Future<void> _maybeCompressHistory() async {
    final repo = _repository();
    final sessionId = _sessionId;
    final llm = ZephyrScope.of(context).llmSettings;
    if (repo == null || sessionId == null || !llm.isConfigured) return;
    final stored = await repo.listAiChatMessages(sessionId);
    final session = await repo.getAiChatSession(sessionId);
    if (session == null) return;
    if (!aiChatShouldCompressHistory(
      messages: stored,
      maxInputTokens: llm.preferences.maxInputTokens,
      contextSummary: session.contextSummary,
    )) {
      return;
    }
    final transcript = aiChatTranscriptForCompression(stored);
    if (transcript.isEmpty) return;
    final addition = await llm.summarizeForContextCompression(transcript);
    if (addition.isEmpty) return;
    final merged = mergeAiChatContextSummaries(
      existing: session.contextSummary,
      addition: addition,
    );
    final keepFrom = stored.length > 8
        ? stored[stored.length - 8].sortOrder
        : 0;
    await repo.updateAiChatSessionSummary(
      sessionId: sessionId,
      contextSummary: merged,
    );
    await repo.pruneAiChatMessagesBefore(
      sessionId: sessionId,
      keepFromSortOrder: keepFrom,
    );
    _contextSummary = merged;
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(
          stored.where((m) => m.sortOrder >= keepFrom).map(_messageFromStored),
        );
      _seedWelcomeIfEmpty();
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _streamReveal.reset();
    _scrollSaveDebounce?.cancel();
    unawaited(_persistScrollOffset());
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onListScrollOffsetChanged);
    widget.contextSelection?.detachComposer(_composer);
    if (_drawerDragBlockedForList && context.mounted) {
      ZephyrDrawerDragBlockNotification(blocked: false).dispatch(context);
    }
    _liveAssistant.dispose();
    _scrollController.dispose();
    _composer.dispose();
    super.dispose();
  }

  void _stopGeneration() {
    if (!_sending) return;
    ZephyrScope.of(context).llmSettings.cancelChat();
    _revealTimer?.cancel();
    _revealTimer = null;
    _streamReveal.snap();
    if (_liveAssistantMessageIndex >= 0) {
      _publishStreamReveal();
    }
  }

  Future<void> _send() async {
    if (_composer.isEmpty || _sending || _loadingSession) return;
    final displayText = _composer.composeDisplayText();
    final library = widget.libraryModel;
    final llmUserText = await composeLlmUserMessage(
      composer: _composer,
      loadChapterBlock: (articleId, title) async {
        if (library == null) return '## $title\n\n(无法加载正文)';
        try {
          final full = await library.repository.getArticle(articleId);
          return '## $title\n\n${full.content}';
        } on Object {
          return '## $title\n\n(无法加载正文)';
        }
      },
    );
    if (llmUserText.isEmpty) return;
    final l10n = context.l10n;
    final llm = ZephyrScope.of(context).llmSettings;
    final repo = _repository();
    if (repo == null) return;
    final sessionId = await _ensurePersistedSessionId();
    if (sessionId == null) return;
    await _maybeCompressHistory();
    final prior = List<_AiChatMessage>.from(_messages);
    setState(() {
      _sending = true;
      _messages.add(
        _AiChatMessage(
          role: _AiChatRole.user,
          text: displayText,
          modelText: llmUserText,
        ),
      );
      _composer.clear();
    });
    final userStored = await repo.appendAiChatMessage(
      sessionId: sessionId,
      role: AiChatMessageRole.user,
      body: displayText,
      modelBody: llmUserText == displayText ? '' : llmUserText,
    );
    if (_messages.isNotEmpty) {
      _messages[_messages.length - 1] = _AiChatMessage(
        storageId: userStored.id,
        role: _AiChatRole.user,
        text: displayText,
        modelText: llmUserText,
      );
    }
    final session = await repo.getAiChatSession(sessionId);
    if (session != null && session.title.length <= 5) {
      final title = displayText.length > 36
          ? '${displayText.substring(0, 36)}…'
          : displayText;
      await repo.renameAiChatSession(sessionId: sessionId, title: title);
    }
    _scrollToEnd(animate: true, force: true);
    var assistantIndex = -1;
    String? assistantStorageId;
    final expectsThinking =
        llm.isConfigured &&
        llm.preferences.allowThinking &&
        llm.preferences.effectiveThinkingLevel() != LlmThinkingLevel.off;
    if (llm.isConfigured && (llm.preferences.streamOutput || expectsThinking)) {
      final placeholder = await repo.appendAiChatMessage(
        sessionId: sessionId,
        role: AiChatMessageRole.assistant,
        body: '',
      );
      assistantStorageId = placeholder.id;
      setState(() {
        _messages.add(
          _AiChatMessage(
            storageId: assistantStorageId,
            role: _AiChatRole.assistant,
            text: '',
            thinkingInProgress: expectsThinking,
          ),
        );
        assistantIndex = _messages.length - 1;
        _liveAssistantMessageIndex = assistantIndex;
        _revealTimer?.cancel();
        _revealTimer = null;
        _streamReveal.reset();
        _streamReveal.thinkingInProgress = expectsThinking;
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
        final summary = _contextSummary.trim();
        final turns = <LlmChatMessage>[
          if (summary.isNotEmpty)
            LlmChatMessage(
              role: LlmChatRole.system,
              text: '${l10n.aiChatCompressedContextHeader}\n\n$summary',
            ),
          for (final message in prior)
            if (message.role != _AiChatRole.assistant ||
                message.text != l10n.aiChatWelcome)
              LlmChatMessage(
                role: message.role == _AiChatRole.assistant
                    ? LlmChatRole.assistant
                    : LlmChatRole.user,
                text: message.promptText,
              ),
          LlmChatMessage(role: LlmChatRole.user, text: llmUserText),
        ];
        replyResult = await llm.completeChat(
          messages: turns,
          onPartial: assistantIndex >= 0
              ? (partial) {
                  if (!mounted) return;
                  _streamReveal.thinkingInProgress = partial.thinkingInProgress;
                  _streamReveal.setTargets(
                    text: partial.text,
                    thinking: partial.thinking,
                  );
                  _pumpStreamReveal();
                }
              : null,
        );
        replyText = replyResult.text;
        if (assistantIndex >= 0) {
          _streamReveal.thinkingInProgress = false;
          _streamReveal.setTargets(
            text: replyResult.text,
            thinking: replyResult.thinking,
          );
          _pumpStreamReveal();
          await _streamReveal.whenCaughtUp().timeout(
            const Duration(seconds: 20),
            onTimeout: _streamReveal.snap,
          );
        }
      }
    } on Object catch (error) {
      replyText = l10n.aiChatError(error.toString());
      _streamReveal.snap();
    }
    if (!mounted) return;
    _revealTimer?.cancel();
    _revealTimer = null;
    _liveAssistantMessageIndex = -1;
    _liveAssistant.value = null;
    final thinking = replyResult?.thinking ?? '';
    if (assistantStorageId != null) {
      await repo.updateAiChatMessage(
        messageId: assistantStorageId,
        body: replyText,
        thinking: thinking,
      );
    } else if (replyText.isNotEmpty) {
      final stored = await repo.appendAiChatMessage(
        sessionId: sessionId,
        role: AiChatMessageRole.assistant,
        body: replyText,
        thinking: thinking,
      );
      assistantStorageId = stored.id;
    }
    setState(() {
      _sending = false;
      if (assistantIndex >= 0) {
        _messages[assistantIndex] = _AiChatMessage(
          storageId: assistantStorageId,
          role: _AiChatRole.assistant,
          text: replyText,
          thinking: thinking,
          thinkingInProgress: false,
        );
      } else {
        _messages.add(
          _AiChatMessage(
            storageId: assistantStorageId,
            role: _AiChatRole.assistant,
            text: replyText,
            thinking: thinking,
          ),
        );
      }
    });
  }

  void _publishStreamReveal() {
    _liveAssistant.value = _StreamAssistantFrame(
      text: _streamReveal.visibleText,
      thinking: _streamReveal.visibleThinking,
      thinkingInProgress:
          _streamReveal.thinkingInProgress || !_streamReveal.thinkingCaughtUp,
    );
  }

  void _pumpStreamReveal() {
    if (_revealTimer != null) return;
    void tick() {
      _revealTimer = null;
      if (!mounted) return;
      if (_streamReveal.advance()) _publishStreamReveal();
      if (_streamReveal.isCaughtUp) return;
      _revealTimer = Timer(_streamReveal.nextDelay(), tick);
    }

    tick();
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

  Widget _messageBubble({
    required int index,
    required double bubbleRadius,
    required bool hideAvatar,
  }) {
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
            radius: bubbleRadius,
            hideAvatar: hideAvatar,
            markdownLiveStream: frame != null,
          );
        },
      );
    }
    return _AiChatBubble(
      key: ValueKey('chat-msg-$index'),
      message: _messages[index],
      radius: bubbleRadius,
      hideAvatar: hideAvatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeVm = ZephyrScope.of(context).theme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return ListenableBuilder(
      listenable: themeVm,
      builder: (context, _) {
        final bubbleRadius = themeVm.ui.chatBubbleCornerRadius;
        final hideAvatar = themeVm.ui.hideAiAssistantAvatar;
        final immersiveChrome = widget.bleedEditorBackground;
        final listTopPadding = immersiveChrome
            ? widget.contentTopInset + 12
            : 12.0;
        // Keyboard sits under the composer; both cover the bottom of the list.
        final coveredBottom = _composerOverlayHeight + keyboardInset;
        final listBottomPadding = coveredBottom + 8;
        final trackTop = immersiveChrome ? widget.contentTopInset : 0.0;
        final messageList = _loadingSession
            ? const Center(child: CircularProgressIndicator())
            : Opacity(
                opacity: _holdListUntilScrollRestored ? 0 : 1,
                child: IgnorePointer(
                  ignoring: _holdListUntilScrollRestored,
                  child: _AiChatScrollbar(
                    controller: _scrollController,
                    topInset: trackTop,
                    bottomInset: coveredBottom,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleListScrollNotification,
                      child: ScrollConfiguration(
                        behavior: const _AiChatListScrollBehavior(),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: widget.contentPadding.copyWith(
                            top: listTopPadding,
                            bottom: listBottomPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var index = 0;
                                index < _messages.length;
                                index++
                              )
                                _messageBubble(
                                  index: index,
                                  bubbleRadius: bubbleRadius,
                                  hideAvatar: hideAvatar,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );

        return ColoredBox(
          color: immersiveChrome
              ? Colors.transparent
              : theme.colorScheme.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  if (!immersiveChrome)
                    SizedBox(height: widget.contentTopInset),
                  Expanded(child: messageList),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: _AiChatComposerSizeReporter(
                    onHeightChanged: (height) {
                      if (height == _composerOverlayHeight) return;
                      setState(() => _composerOverlayHeight = height);
                    },
                    child: _AiChatComposer(
                      composer: _composer,
                      sending: _sending,
                      onSend: () => unawaited(_send()),
                      onStop: _stopGeneration,
                      onOpenOptions: () => unawaited(
                        showWorkspaceAiChatOptionsSheet(
                          context,
                          onManageSessions: openSessionsSheet,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Reports the floating composer height so the message list can scroll beneath it.
class _AiChatComposerSizeReporter extends StatefulWidget {
  const _AiChatComposerSizeReporter({
    required this.onHeightChanged,
    required this.child,
  });

  final ValueChanged<double> onHeightChanged;
  final Widget child;

  @override
  State<_AiChatComposerSizeReporter> createState() =>
      _AiChatComposerSizeReporterState();
}

class _AiChatComposerSizeReporterState
    extends State<_AiChatComposerSizeReporter> {
  double? _lastHeight;

  void _reportSize() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = box.size.height;
    if (height == _lastHeight) return;
    _lastHeight = height;
    widget.onHeightChanged(height);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
        return false;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }
}

class _AiChatComposer extends StatelessWidget {
  const _AiChatComposer({
    required this.composer,
    required this.sending,
    required this.onSend,
    required this.onStop,
    required this.onOpenOptions,
  });

  static const _outerRadius = 50.0;

  static Color _composerFill(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.dark
        ? Color.lerp(Colors.black, scheme.surface, 0.1)!
        : Color.lerp(Colors.white, scheme.surface, 0.06)!;
  }

  final WorkspaceAiComposerController composer;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final fill = _composerFill(scheme, theme.brightness);
    final fieldStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurface,
      height: 1.45,
    );
    final hintStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.45,
    );
    final shadow = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.1);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: zephyrContinuousRoundedDecoration(
                color: fill,
                radius: _outerRadius,
                shadows: [
                  BoxShadow(
                    color: shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TapRegion(
                groupId: _aiChatComposerTapGroup,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                      child: WorkspaceAiChatComposerField(
                        composer: composer,
                        hintText: l10n.aiChatInputHint,
                        style: fieldStyle,
                        hintStyle: hintStyle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _AiChatComposerProviderButton(
                            inputFocus: composer.activeFocusNode,
                            onSurfaceVariant: scheme.onSurfaceVariant,
                            onOpenOptions: onOpenOptions,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: sending ? null : onOpenOptions,
                            tooltip: l10n.aiChatSessionOptionsTitle,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: scheme.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                              splashFactory: NoSplash.splashFactory,
                              highlightColor: Colors.transparent,
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 22),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Tooltip(
                            message: sending
                                ? l10n.aiChatStopGenerating
                                : l10n.aiChatSend,
                            child: Material(
                              color: scheme.primary,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: sending ? onStop : onSend,
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: Center(
                                    child: sending
                                        ? DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: scheme.onPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(2.5),
                                            ),
                                            child: const SizedBox(
                                              width: 12,
                                              height: 12,
                                            ),
                                          )
                                        : Icon(
                                            Icons.send_rounded,
                                            size: 18,
                                            color: scheme.onPrimary,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatComposerProviderButton extends StatelessWidget {
  const _AiChatComposerProviderButton({
    required this.inputFocus,
    required this.onSurfaceVariant,
    required this.onOpenOptions,
  });

  final FocusNode inputFocus;
  final Color onSurfaceVariant;
  final VoidCallback onOpenOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = ZephyrScope.of(context).llmSettings;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final prefs = vm.preferences;
        final kind = prefs.effectiveChatProvider;
        final zh = l10n.localeName.startsWith('zh');
        final label = vm.configuredProviders.isEmpty
            ? l10n.llmModelNotSelected
            : (zh
                  ? LlmProviderCatalog.labelZh(kind)
                  : LlmProviderCatalog.labelEn(kind));
        return _AiChatComposerPickerButton(
          icon: Icons.hub_outlined,
          label: label,
          iconColor: onSurfaceVariant,
          labelColor: onSurfaceVariant,
          maxLabelWidth: 120,
          onTap: onOpenOptions,
        );
      },
    );
  }
}

class _AiChatComposerPickerButton extends StatelessWidget {
  const _AiChatComposerPickerButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.maxLabelWidth,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final double maxLabelWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(color: labelColor);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
              Icon(Icons.expand_more_rounded, size: 18, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the plain-text editor: always scrollable + Material stretch overscroll.
/// Same thumb as the plain-text editor. The track stops above the composer
/// and the soft keyboard.
class _AiChatScrollbar extends StatelessWidget {
  const _AiChatScrollbar({
    required this.controller,
    required this.child,
    required this.topInset,
    required this.bottomInset,
  });

  final ScrollController controller;
  final Widget child;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final mobile =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    if (mobile) {
      return ZephyrEditorScrollbar(
        controller: controller,
        padding: EdgeInsets.only(top: topInset),
        bottomTrackInset: bottomInset,
        child: child,
      );
    }
    return RawScrollbar(
      controller: controller,
      padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
      thumbVisibility: false,
      interactive: true,
      child: child,
    );
  }
}

class _AiChatListScrollBehavior extends ScrollBehavior {
  const _AiChatListScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Parent wraps with ZephyrEditorScrollbar (mobile) or Scrollbar (desktop).
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
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
    this.storageId,
    required this.role,
    required this.text,
    this.modelText = '',
    this.thinking = '',
    this.thinkingInProgress = false,
  });

  final String? storageId;
  final _AiChatRole role;
  final String text;

  /// Chapter-expanded text for the model. Empty uses [text].
  final String modelText;
  final String thinking;
  final bool thinkingInProgress;

  bool get hasThinking => thinking.trim().isNotEmpty;

  String get promptText {
    final expanded = modelText.trim();
    if (expanded.isNotEmpty) return modelText;
    return text;
  }
}

class _AiChatBubble extends StatefulWidget {
  const _AiChatBubble({
    super.key,
    required this.message,
    required this.radius,
    this.hideAvatar = false,
    this.markdownLiveStream = false,
  });

  final _AiChatMessage message;
  final double radius;
  final bool hideAvatar;
  final bool markdownLiveStream;

  @override
  State<_AiChatBubble> createState() => _AiChatBubbleState();
}

class _AiChatBubbleState extends State<_AiChatBubble> {
  var _thinkingExpanded = false;

  String _assistantMarkdownBundle(_AiChatMessage message) {
    final parts = <String>[];
    if (_thinkingExpanded && message.hasThinking) {
      parts.add(message.thinking);
    }
    if (message.text.trim().isNotEmpty) {
      parts.add(message.text);
    }
    return parts.join('\n\n');
  }

  Future<void> _copyBubbleText(_AiChatMessage message) async {
    final text = message.role == _AiChatRole.user
        ? message.text
        : _assistantMarkdownBundle(message);
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isUser = message.role == _AiChatRole.user;
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final thinkingFg =
        theme.textTheme.labelSmall?.color ?? theme.colorScheme.onSurfaceVariant;
    final showThinkingUi =
        !isUser && (message.thinkingInProgress || message.hasThinking);
    final thinkingLabel = message.thinkingInProgress
        ? l10n.aiChatThinkingInProgress
        : l10n.aiChatThinkingProcess;
    final bodyText = message.text.isNotEmpty
        ? message.text
        : (message.thinkingInProgress && !message.hasThinking
              ? ''
              : message.text);
    final assistantReplyMarkdown = !isUser && message.text.trim().isNotEmpty
        ? message.text
        : '';
    final showThinkingBody =
        !isUser && _thinkingExpanded && message.hasThinking;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && !widget.hideAvatar) ...[
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
              child: GestureDetector(
                onLongPress: () => unawaited(_copyBubbleText(message)),
                child: DecoratedBox(
                  decoration: zephyrChatBubbleDecoration(
                    color: bg,
                    isUser: isUser,
                    radius: widget.radius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                                          color: thinkingFg,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    thinkingLabel,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: thinkingFg,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _thinkingExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    color: thinkingFg,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (message.thinkingInProgress &&
                              message.hasThinking &&
                              !_thinkingExpanded)
                            const SizedBox(height: 4),
                        ],
                        if (isUser && bodyText.isNotEmpty)
                          SelectionArea(
                            child: SelectableText(
                              bodyText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: fg,
                                height: 1.45,
                              ),
                            ),
                          )
                        else ...[
                          if (showThinkingBody)
                            widget.markdownLiveStream &&
                                    message.thinkingInProgress
                                ? ZephyrStreamingMarkdownBody(
                                    data: message.thinking,
                                    foreground: thinkingFg,
                                    baseStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: thinkingFg,
                                          height: 1.45,
                                        ),
                                  )
                                : ZephyrMarkdownBody(
                                    data: message.thinking,
                                    foreground: thinkingFg,
                                    selectable: false,
                                    baseStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: thinkingFg,
                                          height: 1.45,
                                        ),
                                  ),
                          if (showThinkingBody &&
                              assistantReplyMarkdown.isNotEmpty)
                            const SizedBox(height: 8),
                          if (assistantReplyMarkdown.isNotEmpty)
                            widget.markdownLiveStream &&
                                    !message.thinkingInProgress
                                ? ZephyrStreamingMarkdownBody(
                                    data: assistantReplyMarkdown,
                                    foreground: fg,
                                    baseStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(color: fg, height: 1.45),
                                  )
                                : ZephyrMarkdownBody(
                                    data: assistantReplyMarkdown,
                                    foreground: fg,
                                    selectable: false,
                                    baseStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(color: fg, height: 1.45),
                                  ),
                        ],
                      ],
                    ),
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
