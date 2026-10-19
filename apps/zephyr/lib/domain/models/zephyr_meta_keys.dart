/// [ZephyrMeta] keys stored in Room.db (included in `.pwb` backups).
abstract final class ZephyrMetaKeys {
  /// Full [QuickToolbarConfig] JSON (pinned/custom/phrases/format checks).
  static const quickToolbarConfig = 'quick_toolbar_config';

  /// Legacy: format checkboxes only (migrated on read).
  static const quickToolbarFormatSelection = 'quick_toolbar_format_selection';

  /// Last opened AI session per article (`articleId` → session id).
  static const aiChatActiveSession = 'ai_chat_active_session';

  /// AI chat list scroll offsets (`sessionId` or `article:<id>` → pixels).
  static const aiChatScrollOffsets = 'ai_chat_scroll_offsets';

  /// Per-article editor scroll + caret (`articleId` → [ArticleEditorState] JSON).
  static const articleEditorStates = 'article_editor_states';

  /// Per-book sidebar volume expansion (`bookId` → [SidebarVolumeExpansionEntry] JSON).
  static const sidebarVolumeExpansionByBook = 'sidebar_volume_expansion_by_book';
}
