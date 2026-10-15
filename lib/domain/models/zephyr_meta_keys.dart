/// [ZephyrMeta] keys stored in Room.db (included in `.pwb` backups).
abstract final class ZephyrMetaKeys {
  /// Full [QuickToolbarConfig] JSON (pinned/custom/phrases/format checks).
  static const quickToolbarConfig = 'quick_toolbar_config';

  /// Legacy: format checkboxes only (migrated on read).
  static const quickToolbarFormatSelection = 'quick_toolbar_format_selection';
}
