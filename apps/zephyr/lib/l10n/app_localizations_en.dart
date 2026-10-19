// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zephyr';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionBack => 'Back';

  @override
  String get untitled => 'Untitled';

  @override
  String get untitledLibrary => 'Untitled library';

  @override
  String get temporaryLibraryName => 'Temporary library';

  @override
  String get platformDefaultFont => 'LXGW WenKai (default)';

  @override
  String get searchHint => 'Search';

  @override
  String get dropdownHintSelect => 'Select';

  @override
  String get dropdownNoMatches => 'No matches';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'App interface language.';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDesktopHeader => 'Settings';

  @override
  String get settingsSearchHint => 'Search settings';

  @override
  String get settingsBackTooltip => 'Back';

  @override
  String get settingsCustomColorsTitle => 'Custom colors';

  @override
  String get settingsComingSoonTitle => 'Coming soon';

  @override
  String get settingsComingSoonSubtitle =>
      'These options are still being prepared.';

  @override
  String get settingsPlaceholderBody =>
      'Related options will appear here later.';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionCloud => 'Backup';

  @override
  String get backupGroupLocalTitle => 'Local backup';

  @override
  String get backupGroupCloudTitle => 'Cloud sync';

  @override
  String get cloudSyncSubtitleSignedOut =>
      'Connect Nutstore WebDAV for cloud backup and sync';

  @override
  String cloudSyncSubtitleSignedIn(String name) {
    return 'Signed in as $name';
  }

  @override
  String get cloudBackupQuickTooltip => 'Cloud backup';

  @override
  String get cloudBackupQuickTooltipUnconfigured =>
      'Connect Nutstore for cloud backup';

  @override
  String get cloudSyncEnableTitle => 'Enable cloud backup';

  @override
  String get cloudSyncEnableSubtitle =>
      'Upload local backups to Nutstore on exit or after mobile backgrounding with edits';

  @override
  String get cloudSyncLoginTitle => 'Connect Nutstore';

  @override
  String get cloudSyncLoginSubtitle =>
      'Enter your account, WebDAV URL, and app password';

  @override
  String get cloudSyncSettingsTitle => 'Nutstore settings';

  @override
  String cloudSyncSettingsSubtitle(String name) {
    return 'Signed in as $name';
  }

  @override
  String get cloudSyncUnbindTitle => 'Disconnect';

  @override
  String get cloudSyncLogoutTitle => 'Sign out';

  @override
  String get cloudSyncLogoutSubtitle => 'Stops cloud backup';

  @override
  String get cloudSyncBackupNowTitle => 'Back up to cloud now';

  @override
  String get cloudSyncBackupNowSubtitle =>
      'Create a backup on this device, then upload it to the Zephyr folder on Nutstore';

  @override
  String get cloudSyncBackupNowSuccess => 'Cloud backup completed.';

  @override
  String get cloudSyncRestoreTitle => 'Restore from cloud';

  @override
  String get cloudSyncRestoreSubtitle =>
      'Pick a backup from Nutstore — overwrite or merge';

  @override
  String get cloudSyncRestoreEmpty => 'No cloud backups found.';

  @override
  String get cloudSyncLatestSnapshotTitle => 'Latest cloud backup';

  @override
  String get cloudSyncLatestSnapshotSubtitle => 'Current snapshot on Nutstore';

  @override
  String get cloudSyncRestoreSuccess => 'Library restored from cloud backup.';

  @override
  String cloudSyncFailed(String error) {
    return 'Cloud sync failed: $error';
  }

  @override
  String get cloudSyncAnotherLibrary =>
      'This Zephyr cloud folder belongs to another library. Choose the original local directory or another WebDAV account; cloud sync has stopped.';

  @override
  String get cloudSyncMissingManifest =>
      'The Zephyr folder in the cloud looks incomplete. Sort it out before syncing again.';

  @override
  String get cloudSyncWaitBeforeChoosingDirectory =>
      'Wait for cloud sync to finish before choosing another directory.';

  @override
  String get cloudSyncCredentialsTitle => 'Connect Nutstore WebDAV';

  @override
  String get cloudSyncCredentialsEditTitle => 'Nutstore settings';

  @override
  String get cloudSyncCredentialsSubtitle =>
      'Use a Nutstore app password, not your account password. Stored securely on this device.';

  @override
  String get cloudSyncCredentialsPasswordHint =>
      'Leave blank to keep the current app password';

  @override
  String get cloudSyncCredentialsSave => 'Connect';

  @override
  String get cloudSyncCredentialsSaveEdit => 'Save';

  @override
  String get cloudSyncCredentialsSaved => 'Nutstore connected';

  @override
  String get cloudSyncCredentialsUpdated => 'Nutstore settings saved';

  @override
  String get cloudSyncClientIdLabel => 'Nutstore account';

  @override
  String get cloudSyncServerUrlLabel => 'WebDAV URL';

  @override
  String get cloudSyncClientSecretLabel => 'App password';

  @override
  String get backupAutoTitle => 'Automatic backup';

  @override
  String get backupAutoSubtitle =>
      'Back up edited content hourly, and on mobile backgrounding. Keep the latest 25 local backups.';

  @override
  String get backupNowTitle => 'Back up now';

  @override
  String get backupNowSubtitle =>
      'Create a manual backup now. Manual and automatic backups together keep the latest 25.';

  @override
  String get backupNowSuccess => 'Backup completed.';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String saveFailed(String error) {
    return 'Saving failed. Your edits remain open; retry before exiting: $error';
  }

  @override
  String get exitBackupInProgress => 'Saving…';

  @override
  String get backupRestoreTitle => 'Restore backup';

  @override
  String backupRestoreSubtitle(int count) {
    return '$count backups available — overwrite or merge.';
  }

  @override
  String get backupRestoreEmpty => 'No backup files found.';

  @override
  String get backupRestoreModeTitle => 'Restore mode';

  @override
  String get backupRestoreModeMerge => 'Merge (keep the newer version)';

  @override
  String get backupRestoreModeOverwrite =>
      'Overwrite (replace the whole library)';

  @override
  String get backupRestoreConfirmTitle => 'Confirm restore';

  @override
  String get backupRestoreConfirmMerge =>
      'Merge the selected backup into the current library. A safety backup is created first.';

  @override
  String get backupRestoreConfirmOverwrite =>
      'Replace the current library with the selected backup. A safety backup is created first.';

  @override
  String get backupRestoreAction => 'Restore';

  @override
  String get backupRestoreSuccess => 'Library restored from backup.';

  @override
  String get backupMergeResultTitle => 'Merge complete';

  @override
  String get backupMergeResultSeparator => ', ';

  @override
  String get backupMergeResultNoChanges =>
      'Merge complete. No chapter changes.';

  @override
  String backupMergeResultAdded(int count) {
    return 'Added $count';
  }

  @override
  String backupMergeResultUpdated(int count) {
    return 'Updated $count';
  }

  @override
  String backupMergeResultRemoved(int count) {
    return 'Deleted $count';
  }

  @override
  String get backupKindAuto => 'Auto';

  @override
  String get backupKindManual => 'Manual';

  @override
  String get backupFooter =>
      'Don\'t open the same library in Pure Writer at the same time. Backup files can be opened in Pure Writer.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No history revisions yet.';

  @override
  String get historyEmptyRevision => '(empty)';

  @override
  String get historyRestoreTitle => 'Restore this revision?';

  @override
  String get historyRestoreBody =>
      'The current chapter text will be replaced by this revision and recorded in History.';

  @override
  String get historyRestoreAction => 'Restore';

  @override
  String get historyRestoreSuccess => 'Restored to the selected revision.';

  @override
  String get historyMenuLabel => 'History';

  @override
  String get draftRecoverTitle => 'Unsaved draft found';

  @override
  String get draftRecoverBody =>
      'A draft newer than the library was found. Restore it?';

  @override
  String get draftRecoverAction => 'Restore';

  @override
  String get draftDismissAction => 'Discard';

  @override
  String get settingsSectionEditor => 'Editor';

  @override
  String get settingsSectionShortcuts => 'Shortcuts';

  @override
  String get shortcutsManageTitle => 'Customize shortcuts';

  @override
  String get shortcutsManageSubtitle => 'View and change key bindings';

  @override
  String get shortcutsResetAll => 'Reset all to defaults';

  @override
  String get shortcutsResetAction => 'Reset';

  @override
  String get shortcutsClearAction => 'Clear';

  @override
  String get shortcutsRecordTitle => 'Press a new shortcut';

  @override
  String get shortcutsRecordHint => 'Esc to cancel · Backspace to clear';

  @override
  String get shortcutsUnbound => 'Unbound';

  @override
  String get shortcutsConflictHint => 'Conflicting shortcuts were replaced';

  @override
  String get shortcutGroupClipboard => 'Clipboard';

  @override
  String get shortcutGroupHistory => 'History';

  @override
  String get shortcutGroupDelete => 'Delete';

  @override
  String get shortcutGroupIndent => 'Indent';

  @override
  String get shortcutGroupNewline => 'Newline';

  @override
  String get shortcutGroupNavigate => 'Navigate';

  @override
  String get shortcutGroupSelect => 'Select';

  @override
  String get shortcutGroupWorkspace => 'Workspace';

  @override
  String get shortcutActionCopy => 'Copy';

  @override
  String get shortcutActionCut => 'Cut';

  @override
  String get shortcutActionPaste => 'Paste';

  @override
  String get shortcutActionSelectAll => 'Select all';

  @override
  String get shortcutActionUndo => 'Undo';

  @override
  String get shortcutActionRedo => 'Redo';

  @override
  String get shortcutActionDeleteBackward => 'Delete backward';

  @override
  String get shortcutActionDeleteForward => 'Delete forward';

  @override
  String get shortcutActionDeleteWordBackward => 'Delete word backward';

  @override
  String get shortcutActionDeleteWordForward => 'Delete word forward';

  @override
  String get shortcutActionIndent => 'Indent';

  @override
  String get shortcutActionOutdent => 'Outdent';

  @override
  String get shortcutActionNewline => 'Newline';

  @override
  String get shortcutActionMoveLeft => 'Move left';

  @override
  String get shortcutActionMoveRight => 'Move right';

  @override
  String get shortcutActionMoveUp => 'Move up';

  @override
  String get shortcutActionMoveDown => 'Move down';

  @override
  String get shortcutActionMoveWordLeft => 'Move word left';

  @override
  String get shortcutActionMoveWordRight => 'Move word right';

  @override
  String get shortcutActionMoveLineStart => 'Line start';

  @override
  String get shortcutActionMoveLineEnd => 'Line end';

  @override
  String get shortcutActionMovePageUp => 'Page up';

  @override
  String get shortcutActionMovePageDown => 'Page down';

  @override
  String get shortcutActionMoveDocumentStart => 'Document start';

  @override
  String get shortcutActionMoveDocumentEnd => 'Document end';

  @override
  String get shortcutActionSelectLeft => 'Select left';

  @override
  String get shortcutActionSelectRight => 'Select right';

  @override
  String get shortcutActionSelectUp => 'Select up';

  @override
  String get shortcutActionSelectDown => 'Select down';

  @override
  String get shortcutActionSelectWordLeft => 'Select word left';

  @override
  String get shortcutActionSelectWordRight => 'Select word right';

  @override
  String get shortcutActionSelectLineStart => 'Select to line start';

  @override
  String get shortcutActionSelectLineEnd => 'Select to line end';

  @override
  String get shortcutActionSelectPageUp => 'Select page up';

  @override
  String get shortcutActionSelectPageDown => 'Select page down';

  @override
  String get shortcutActionSelectDocumentStart => 'Select to document start';

  @override
  String get shortcutActionSelectDocumentEnd => 'Select to document end';

  @override
  String get shortcutActionCloseSettings => 'Close settings';

  @override
  String get shortcutActionCloudBackupNow => 'Back up to cloud now';

  @override
  String get settingsSectionTheme => 'Theme';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsSectionAi => 'AI';

  @override
  String get aboutSettingsListSubtitle => 'Version, updates, and links';

  @override
  String aboutVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get aboutGitHubTitle => 'GitHub';

  @override
  String get aboutCheckUpdatesTitle => 'Check for updates';

  @override
  String get aboutCheckUpdatesSubtitle =>
      'Fetch the latest release info from GitHub.';

  @override
  String get aboutCheckUpdatesComingSoon => 'Update checks are coming soon.';

  @override
  String get aboutOpenLinkFailed => 'Could not open the link.';

  @override
  String get generalSectionTitle => 'General';

  @override
  String get immersiveStatusBarTitle => 'Immersive status bar';

  @override
  String get immersiveStatusBarSubtitle =>
      'The app extends under a transparent status bar, and text can scroll into that area.';

  @override
  String get hideStatusBarIconsTitle => 'Hide status bar icons';

  @override
  String get hideStatusBarIconsSubtitle =>
      'Only while the immersive status bar is on. Icons hide on their own; swipe from the edge to show them briefly.';

  @override
  String get mobileBehaviorSectionTitle => 'Mobile';

  @override
  String get mobileBehaviorSectionSubtitle => 'Applies to phones and tablets.';

  @override
  String get scrollToHideMobileTopBarTitle => 'Hide top bar while scrolling';

  @override
  String get scrollToHideMobileTopBarSubtitle =>
      'Collapse the floating book bar when scrolling down; show it when scrolling up.';

  @override
  String get openSidebarAfterBookSwitchTitle =>
      'Open chapter list after switching books';

  @override
  String get openSidebarAfterBookSwitchSubtitle =>
      'Show the chapter list after you pick another book.';

  @override
  String get keepScreenOnTitle => 'Keep screen on';

  @override
  String get keepScreenOnSubtitle =>
      'Prevent the display from sleeping while the app is open.';

  @override
  String get doubleBackToExitTitle => 'Press back twice to exit';

  @override
  String get doubleBackToExitSubtitle =>
      'When off, a single back press exits the app.';

  @override
  String get openBookListOnStartupTitle => 'Open book list on launch';

  @override
  String get openBookListOnStartupSubtitle =>
      'Show the book picker when the workspace opens.';

  @override
  String get openSidebarOnStartupTitle => 'Open chapter list on launch';

  @override
  String get openSidebarOnStartupSubtitle =>
      'Show the chapter list when the workspace opens.';

  @override
  String get desktopBehaviorSectionTitle => 'Desktop workspace';

  @override
  String get desktopBehaviorSectionSubtitle =>
      'Applies to the desktop writing layout.';

  @override
  String get desktopFloatingSidebarTitle => 'Floating sidebar on hover';

  @override
  String get desktopFloatingSidebarSubtitle =>
      'Move the pointer to the left screen edge to show the chapter list over the editor; hides when the pointer leaves.';

  @override
  String get desktopFloatingAiPanelTitle => 'Floating AI panel';

  @override
  String get desktopFloatingAiPanelSubtitle =>
      'Show AI chat over the editor on the right instead of resizing the writing column.';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get aiFeaturesEnabledTitle => 'AI assistant';

  @override
  String get aiFeaturesEnabledSubtitle =>
      'When off, the AI button is hidden in the workspace and any open assistant returns to the book.';

  @override
  String get hideAiAssistantAvatarTitle => 'Hide assistant avatar';

  @override
  String get hideAiAssistantAvatarSubtitle =>
      'Hide the avatar so chat bubbles line up on both sides.';

  @override
  String get hideQuickToolbarTitle => 'Hide quick input bar';

  @override
  String get hideQuickToolbarSubtitle =>
      'When on, the accessory toolbar above the keyboard is hidden.';

  @override
  String get showChapterDetailsTitle => 'Show chapter details';

  @override
  String get showChapterDetailsSubtitle =>
      'When off, the sidebar shows chapter titles only.';

  @override
  String get editorSectionTitle => 'Editor';

  @override
  String get editorSectionIntro =>
      'Font and layout preferences apply right away.';

  @override
  String get editorSectionFooter =>
      'Changes apply to the writing area immediately.';

  @override
  String get editorFontLabel => 'Font';

  @override
  String get editorFontDescription =>
      'Font used while writing. Imported fonts can also be used in the interface.';

  @override
  String get editorFontSizeTitle => 'Font size';

  @override
  String get editorFontSizeDescription =>
      'Size of the writing-column body text.';

  @override
  String get editorTitleSizeTitle => 'Title size';

  @override
  String get editorTitleSizeDescription =>
      'Font size of the chapter title above the body.';

  @override
  String get editorTitleCenteredTitle => 'Center title';

  @override
  String get editorTitleCenteredSubtitle =>
      'When on, center the title in the reading column; when off, align it to the body left edge.';

  @override
  String get editorTypewriterModeTitle => 'Typewriter mode';

  @override
  String get editorTypewriterModeSubtitle =>
      'Keeps the editing line centered; dims other paragraphs and the unfocused title.';

  @override
  String get editorJumpToEndOnScrollDownTitle => 'Focus end while scrolling';

  @override
  String get editorJumpToEndOnScrollDownSubtitle =>
      'When on, shows the focus-end button while scrolling down; hides at the bottom or when scrolling up.';

  @override
  String get editorLineHeightTitle => 'Line height';

  @override
  String get editorLineHeightDescription =>
      'Uniform line-height multiplier within a paragraph.';

  @override
  String get editorParagraphSpacingTitle => 'Paragraph spacing';

  @override
  String get editorParagraphSpacingDescription =>
      'Gap between paragraphs, as a font-size multiplier.';

  @override
  String get editorFirstLineIndentTitle => 'First-line indent';

  @override
  String get editorFirstLineIndentDescription =>
      'Width inserted by Tab, and applied when opening chapters. Enter copies the previous paragraph\'s indent.';

  @override
  String get editorMarginLeftTitle => 'Left margin';

  @override
  String get editorMarginLeftDescription =>
      'Left inset of the reading column. When space is tight, both margins shrink in proportion.';

  @override
  String get editorMarginRightTitle => 'Right margin';

  @override
  String get editorMarginRightDescription =>
      'Right inset of the reading column. Equal values stay strictly symmetric.';

  @override
  String get editorWidthTitle => 'Editor width';

  @override
  String get editorWidthDescription =>
      'Width of the text column, always centered. It narrows when the window is too small.';

  @override
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get appearanceSectionIntro =>
      'Choose a palette, or adjust individual colors. Fonts and corner radius stay as you set them.';

  @override
  String get themeModeTitle => 'Theme mode';

  @override
  String get themeModeSubtitle =>
      'Choose light, dark, or follow the system appearance.';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get uiFontLabel => 'UI font';

  @override
  String get uiFontDescription =>
      'Font used for the sidebar, settings, and other interface text. Imported fonts can also be used while writing.';

  @override
  String get uiFontSizeTitle => 'UI font size';

  @override
  String get uiFontSizeDescription =>
      'Size of text in the sidebar, settings, and the rest of the interface.';

  @override
  String get cornerRadiusTitle => 'Corner radius';

  @override
  String get cornerRadiusDescription =>
      'Shared roundness for buttons, menus, cards, and fields.';

  @override
  String get barCornerRadiusTitle => 'Bar corner radius';

  @override
  String get barCornerRadiusDescription =>
      'Roundness of the editor top bar and the bar at the bottom of the sidebar.';

  @override
  String get chatBubbleCornerRadiusTitle => 'Chat bubble corners';

  @override
  String get chatBubbleCornerRadiusDescription =>
      'Roundness of AI chat bubbles. The outer top corner stays square.';

  @override
  String get showBordersTitle => 'Show borders';

  @override
  String get showBordersSubtitle =>
      'When off, buttons and cards have no outline. When on, volumes and the library bar show a border.';

  @override
  String get sidebarItemInsetTitle => 'Sidebar item inset';

  @override
  String get sidebarItemInsetDescription =>
      'Equal left/right padding for volumes and chapters.';

  @override
  String get sidebarItemCornerRadiusTitle => 'Sidebar volume & chapter corners';

  @override
  String get sidebarItemCornerRadiusDescription =>
      'Corner radius for volume headers and chapter rows in the library sidebar.';

  @override
  String get sidebarVolumeGapTitle => 'Sidebar volume spacing';

  @override
  String get sidebarVolumeGapDescription =>
      'Space between volumes. Chapters stay close, separated by a line.';

  @override
  String get themePresetsSectionTitle => 'Theme colors';

  @override
  String get actionCopy => 'Copy';

  @override
  String get themePackRenameTitle => 'Rename theme';

  @override
  String themePackCopyName(String name) {
    return '$name copy';
  }

  @override
  String get themePackDeleteTitle => 'Delete theme?';

  @override
  String themePackDeleteBody(String name) {
    return '“$name” will be removed permanently.';
  }

  @override
  String get themeCurrentCustom => 'Current: Custom';

  @override
  String themeCurrentPreset(String preset) {
    return 'Current: $preset';
  }

  @override
  String get themeCurrentCustomLong => 'Current palette: Custom';

  @override
  String themeCurrentPresetLong(String preset) {
    return 'Current palette: $preset';
  }

  @override
  String get themePresetsFooter =>
      'Palettes only change colors. Fonts, corners, and other layout stay as you set them.';

  @override
  String get customColorsTitle => 'Custom colors';

  @override
  String get customColorsSubtitle =>
      'Adjust colors for the current appearance. Changes apply right away.';

  @override
  String get customizeTokensButton => 'Customize colors';

  @override
  String get backToThemesButton => 'Back to themes';

  @override
  String get themeTokensTitle => 'Theme colors';

  @override
  String get themeTokensIntro =>
      'Enter a color code such as #336699. Changes apply right away.';

  @override
  String get restoreDefaultColors => 'Restore defaults';

  @override
  String get saveAsThemeColor => 'Save as theme';

  @override
  String get saveThemeColorTitle => 'Save as theme color';

  @override
  String get saveThemeColorNameLabel => 'Theme name';

  @override
  String themePackNameDefault(int n) {
    return 'Theme $n';
  }

  @override
  String get themePresetLight => 'Light';

  @override
  String get themePresetGrey => 'Grey';

  @override
  String get themePresetSlate => 'Slate';

  @override
  String get themePresetClaude => 'Claude Code';

  @override
  String get themePresetMint => 'Mint';

  @override
  String get themePresetPurple => 'Purple';

  @override
  String get themePresetHermes => 'Hermes';

  @override
  String get themePresetOcean => 'Ocean';

  @override
  String get themePresetDarkModern => 'Dark Modern';

  @override
  String get tokenEditorSurface => 'Writing background';

  @override
  String get tokenSidebarSurface => 'Sidebar background';

  @override
  String get tokenControlSurface => 'Buttons and fields';

  @override
  String get tokenBorder => 'Border';

  @override
  String get tokenDivider => 'Divider';

  @override
  String get tokenPrimaryText => 'Primary text';

  @override
  String get tokenMutedText => 'Muted text';

  @override
  String get tokenAccent => 'Accent';

  @override
  String get tokenCursor => 'Cursor';

  @override
  String get tokenEditorSurfaceDescription =>
      'Background of the writing column.';

  @override
  String get tokenSidebarSurfaceDescription =>
      'Background of the sidebar and surrounding panels.';

  @override
  String get tokenControlSurfaceDescription =>
      'Fill color for fields, menus, and cards.';

  @override
  String get tokenBorderDescription => 'Outlines around buttons and fields.';

  @override
  String get tokenDividerDescription => 'Sidebar chapter separators.';

  @override
  String get tokenPrimaryTextDescription =>
      'Default title and body copy color.';

  @override
  String get tokenMutedTextDescription =>
      'Softer color for hints and captions.';

  @override
  String get tokenAccentDescription => 'Highlights and selected items.';

  @override
  String get tokenCursorDescription => 'Caret color in the writing editor.';

  @override
  String get fontImportSuccess => 'Font imported into the app library.';

  @override
  String get fontImportFailure => 'Could not import that font file.';

  @override
  String get fontDeleteSuccess => 'Removed from the app font library.';

  @override
  String get fontDeleteFailure => 'Could not delete that font.';

  @override
  String get fontImportFromFile => 'Choose font file…';

  @override
  String get fontDeleteFromLibrary => 'Delete from library';

  @override
  String get fontDeleteDialogTitle => 'Delete font?';

  @override
  String fontDeleteDialogBody(String family) {
    return 'Remove “$family” from the app font library to free space?';
  }

  @override
  String get fontDeleteDialogBodyCompact =>
      'Remove it from the app font library to free space?';

  @override
  String get editorBackgroundSectionTitle => 'Editor background image';

  @override
  String get editorBackgroundEnabledTitle => 'Use background image';

  @override
  String get editorBackgroundEnabledSubtitle =>
      'Turn off to hide without clearing your picks';

  @override
  String get themeColorsSectionTitle => 'Theme colors';

  @override
  String get editorBackgroundLightTitle => 'Light background';

  @override
  String get editorBackgroundDarkTitle => 'Dark background';

  @override
  String get editorBackgroundNone => 'None';

  @override
  String get editorBackgroundCurrentBadge => 'Current';

  @override
  String get editorBackgroundChoose => 'Choose';

  @override
  String get editorBackgroundClear => 'Clear';

  @override
  String get editorBackgroundSelectTitle => 'Choose background';

  @override
  String get editorBackgroundAddFromFile => 'Add from file…';

  @override
  String get editorBackgroundEmptyLibrary =>
      'No images yet. Tap above to add one.';

  @override
  String get editorBackgroundNoImagePreview => 'No background image';

  @override
  String get editorBackgroundPreviewSample =>
      'The quick brown fox jumps over the lazy dog.\nWriting stays sharp above a soft backdrop.';

  @override
  String get editorBackgroundFitTitle => 'Image fit';

  @override
  String get editorBackgroundFitCover => 'Cover';

  @override
  String get editorBackgroundFitContain => 'Contain';

  @override
  String get editorBackgroundFitFill => 'Stretch';

  @override
  String get editorBackgroundFitTile => 'Tile';

  @override
  String get editorBackgroundFitCenter => 'Center';

  @override
  String get editorBackgroundOpacityTitle => 'Background opacity';

  @override
  String get editorBackgroundBlurTitle => 'Background blur';

  @override
  String get editorBackgroundBlurDescription =>
      'Softens the image only. Text stays sharp.';

  @override
  String get editorBackgroundImportSuccess => 'Image added to the app library.';

  @override
  String get editorBackgroundImportFailure => 'Could not import that image.';

  @override
  String get editorBackgroundDeleteSuccess => 'Removed from the app library.';

  @override
  String get editorBackgroundDeleteFailure => 'Could not delete that image.';

  @override
  String get editorBackgroundDeleteTitle => 'Delete image?';

  @override
  String editorBackgroundDeleteBody(String name) {
    return 'Delete “$name”? Modes using it will reset to no background.';
  }

  @override
  String editorBackgroundSummary(String name, String fit, int opacity) {
    return '$name · $fit · $opacity%';
  }

  @override
  String editorBackgroundSummaryWithBlur(
    String name,
    String fit,
    int opacity,
    int blur,
  ) {
    return '$name · $fit · $opacity% · blur $blur';
  }

  @override
  String get choiceDeleteTitle => 'Delete?';

  @override
  String get choiceDeleteBody => 'Remove this item?';

  @override
  String numberPickerDefaultLabel(String value) {
    return 'Default $value';
  }

  @override
  String numberPickerRestoreDefault(String value) {
    return 'Restore default ($value)';
  }

  @override
  String get tempLibraryBannerTitle => 'Using a temporary library';

  @override
  String get tempLibraryBannerSubtitle =>
      'Choose a PureWriter library folder to open your work';

  @override
  String get chooseLibraryButton => 'Choose library';

  @override
  String get librarySetupTitle => 'Welcome to Zephyr';

  @override
  String get librarySetupBody =>
      'Start writing in a local temporary library, or connect an existing PureWriter folder when you are ready.';

  @override
  String get startTemporaryLibraryButton => 'Start writing';

  @override
  String get libraryLoadFailedHint =>
      'Could not open the last library. Start fresh or choose another folder.';

  @override
  String get libraryRecoveredToTemporary =>
      'Opened the temporary library instead. You can reconnect your PureWriter folder from the banner.';

  @override
  String get chooseLibraryDirectoryButton => 'Choose PureWriter folder';

  @override
  String get editorEmptyState => 'Choose or create a chapter to begin writing.';

  @override
  String get jumpToEnd => 'Focus end';

  @override
  String get volumeInsertBelow => 'Insert volume below';

  @override
  String get volumeAppendChapter => 'Insert chapter at end of volume';

  @override
  String get chapterInsertBelow => 'Insert chapter below';

  @override
  String get actionMoveToVolume => 'Move to volume';

  @override
  String get actionMoveToBook => 'Move to book';

  @override
  String get actionConvertVolumeToBook => 'Convert this volume to a book';

  @override
  String get moveToBookSheetTitle => 'Move to book';

  @override
  String get moveToBookNoTargets => 'There are no other books to move into.';

  @override
  String get renameVolumeTitle => 'Rename volume';

  @override
  String get renameChapterTitle => 'Rename chapter';

  @override
  String get volumeNameLabel => 'Volume name';

  @override
  String get chapterNameLabel => 'Chapter name';

  @override
  String get validationNameRequired => 'Please enter a name';

  @override
  String get deleteChapterTitle => 'Delete chapter';

  @override
  String deleteChapterBody(String name) {
    return 'Move “$name” to the trash?';
  }

  @override
  String get deleteVolumeTitle => 'Delete volume';

  @override
  String deleteVolumeBody(String name) {
    return 'When deleting “$name”, choose what to do with its chapters.';
  }

  @override
  String get deleteVolumeOnly => 'Delete volume only';

  @override
  String get deleteVolumeAndChapters => 'Delete volume and chapters';

  @override
  String get moveToVolumeSheetTitle => 'Move to volume';

  @override
  String get unfiledVolume => 'Unfiled';

  @override
  String get unfiledChaptersHeader => 'Unfiled chapters';

  @override
  String get tooltipHideSidebar => 'Hide sidebar';

  @override
  String get tooltipNewVolume => 'New volume';

  @override
  String get tooltipNewChapter => 'New chapter';

  @override
  String get tooltipAdd => 'Add';

  @override
  String get tooltipSearchChapters => 'Search';

  @override
  String get searchSheetTitle => 'Search';

  @override
  String get searchSheetHint => 'Search titles and content';

  @override
  String get searchSheetEmptyQuery => 'Enter a keyword to search.';

  @override
  String get searchSheetNoResults => 'No matching results.';

  @override
  String get searchScopeArticle => 'Chapter';

  @override
  String get searchScopeVolume => 'Volume';

  @override
  String get searchScopeBook => 'Book';

  @override
  String get searchScopeAllBooks => 'All books';

  @override
  String get tooltipLocateCurrentChapter => 'Locate current chapter';

  @override
  String get tooltipCollapseAll => 'Collapse all';

  @override
  String get tooltipExpandAll => 'Expand all';

  @override
  String get tooltipReorder => 'Sort order';

  @override
  String get tooltipDoneReordering => 'Done adjusting order';

  @override
  String get chapterSortManual => 'Manual order';

  @override
  String get chapterSortAdjustOrder => 'Adjust order';

  @override
  String get chapterSortCreatedAsc => 'Created · Oldest first';

  @override
  String get chapterSortCreatedDesc => 'Created · Newest first';

  @override
  String get chapterSortUpdatedAsc => 'Modified · Oldest first';

  @override
  String get chapterSortUpdatedDesc => 'Modified · Newest first';

  @override
  String get chapterSortTitleAsc => 'Name · A→Z';

  @override
  String get chapterSortTitleDesc => 'Name · Z→A';

  @override
  String get tooltipAiAssistant => 'AI assistant';

  @override
  String get aiChatWelcome => 'Tell me what you\'re working on.';

  @override
  String get aiChatInputHint => 'Type a message…';

  @override
  String get aiChatSend => 'Send';

  @override
  String get aiChatStopGenerating => 'Stop generating';

  @override
  String get aiContextRemoveArticle => 'Remove from context';

  @override
  String get llmSettingsTitle => 'AI models';

  @override
  String get llmSettingsSubtitle => 'Provider, API key, and model';

  @override
  String get llmSettingsIntro =>
      'Your key stays on this device. Other settings are included in backups.';

  @override
  String get llmBehaviorSectionTitle => 'Chat behavior';

  @override
  String get llmStreamOutputTitle => 'Streaming output';

  @override
  String get llmStreamOutputSubtitle => 'Show the reply as it is written';

  @override
  String get llmAllowThinkingTitle => 'Allow thinking';

  @override
  String get llmAllowThinkingSubtitle =>
      'Let models that can reason think before they answer';

  @override
  String get llmPresetPromptTitle => 'Preset prompt';

  @override
  String get llmPresetPromptDescription =>
      'Sent as system instructions on every chat—use it for genre, tone, POV, and other standing preferences.';

  @override
  String get llmPresetPromptHint =>
      'e.g. You are a writing assistant. Reply concisely; when continuing prose, match POV, tense, and voice.';

  @override
  String get llmMaxInputTokensTitle => 'Context limit (input)';

  @override
  String get llmMaxInputTokensSubtitle =>
      'Older messages are shortened once this limit is reached';

  @override
  String get llmMaxOutputTokensTitle => 'Reply limit (output)';

  @override
  String get llmMaxOutputTokensSubtitle => 'How long a single reply can be';

  @override
  String get llmThinkingLevelTitle => 'Thinking intensity';

  @override
  String get llmThinkingLevelSubtitle => 'Deeper thinking usually takes longer';

  @override
  String get llmDefaultThinkingLevelTitle => 'Default thinking intensity';

  @override
  String get llmDefaultThinkingLevelSubtitle =>
      'Starting level for new chats. You can change it beside the message box.';

  @override
  String get llmThinkingDisabledInSettings =>
      'Turn on “Allow thinking” in AI model settings first';

  @override
  String get llmThinkingOff => 'Off';

  @override
  String get llmThinkingMinimal => 'Minimal';

  @override
  String get llmThinkingLow => 'Low';

  @override
  String get llmThinkingMedium => 'Medium';

  @override
  String get llmThinkingHigh => 'High';

  @override
  String get llmThinkingAuto => 'Auto';

  @override
  String get aiChatAiSettingsEntry => 'AI settings';

  @override
  String get aiChatSessionOptionsTitle => 'Chat options';

  @override
  String get aiChatSessionProviderTitle => 'Provider';

  @override
  String get aiChatSessionProviderSubtitle =>
      'Use a vendor you configured in AI settings';

  @override
  String get aiChatSessionOptionsNeedTest =>
      'Run a connection test in AI model settings first.';

  @override
  String get aiChatSessionModelSubtitle =>
      'Override the default model from settings';

  @override
  String aiChatThinkingForModel(String model) {
    return 'Model: $model';
  }

  @override
  String get aiChatSessionsTitle => 'Conversations';

  @override
  String get aiChatSessionsSubtitle =>
      'Switch, archive, or delete saved chats for this chapter';

  @override
  String get aiChatNewSession => 'New chat';

  @override
  String get aiChatShowArchivedSessions => 'Show archived';

  @override
  String get aiChatNoSessions => 'No saved conversations yet.';

  @override
  String aiChatSessionUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get aiChatOpenSession => 'Open';

  @override
  String get aiChatArchiveSession => 'Archive';

  @override
  String get aiChatUnarchiveSession => 'Restore from archive';

  @override
  String get aiChatDeleteSession => 'Delete';

  @override
  String get aiChatDeleteSessionTitle => 'Delete conversation?';

  @override
  String aiChatDeleteSessionBody(String title) {
    return 'Delete “$title” and all messages in it? This cannot be undone.';
  }

  @override
  String get aiChatCompressedContextHeader =>
      'Summary of the earlier conversation:';

  @override
  String get llmProviderTitle => 'Provider';

  @override
  String get llmProviderSubtitle =>
      'Configure each vendor; switch without losing other profiles';

  @override
  String get llmApiKeyTitle => 'API key';

  @override
  String get llmApiKeyHint => 'Paste your key';

  @override
  String get llmBaseUrlTitle => 'API base URL';

  @override
  String get llmBaseUrlHint => 'e.g. https://api.example.com/v1';

  @override
  String get llmTestConnection => 'Test connection';

  @override
  String llmTestSuccess(int count) {
    return 'Connected — $count models available';
  }

  @override
  String get llmModelTitle => 'Chat model';

  @override
  String get llmModelSubtitle => 'Available after a successful test';

  @override
  String get llmModelNotSelected => 'Not selected';

  @override
  String get aiChatNotConfigured =>
      'Set up your API key and run a connection test in Settings first.';

  @override
  String get aiChatThinkingInProgress => 'Thinking…';

  @override
  String get aiChatThinkingProcess => 'Thinking process';

  @override
  String aiChatError(String error) {
    return 'Request failed: $error';
  }

  @override
  String aiChatDemoReply(String message) {
    return 'Received: $message';
  }

  @override
  String get tooltipOpenLibrary => 'Open library';

  @override
  String get librarySwitcherChooseDirectory => 'Choose another directory';

  @override
  String get tooltipOpenSidebar => 'Open sidebar';

  @override
  String get tooltipMore => 'More';

  @override
  String get mobileToolsDrawerReorderHint => 'Long-press and drag to reorder.';

  @override
  String get tooltipEditBook => 'Edit book';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get selectBook => 'Select a book';

  @override
  String get booksSheetTitle => 'Books';

  @override
  String get booksSheetTagAll => 'All';

  @override
  String get newBookTitle => 'New book';

  @override
  String get moreSheetTitle => 'Quick tools';

  @override
  String get mobileToolThemeMode => 'Theme mode';

  @override
  String get mobileToolSwitchTheme => 'Switch theme';

  @override
  String get noMobileTools => 'No tools available';

  @override
  String get editBookTitle => 'Edit book';

  @override
  String get bookNameLabel => 'Book title';

  @override
  String get bookNameHint => 'Enter a book title';

  @override
  String get bookNameRequired => 'Please enter a book title';

  @override
  String get tooltipNewBook => 'New book';

  @override
  String get tooltipBookGridLayout => 'Two-column layout';

  @override
  String get tooltipBookListLayout => 'Single-column list';

  @override
  String get tooltipDeleteBook => 'Delete book';

  @override
  String get deleteBookNotEmpty =>
      'Clear all chapters in this book before deleting it.';

  @override
  String get bookTagsLabel => 'Tags';

  @override
  String get bookTagsHint => 'e.g. Literature';

  @override
  String get bookDescriptionLabel => 'Description';

  @override
  String get bookDescriptionHint => 'Briefly describe this book';

  @override
  String bookStatsMeta(int volumes, int chapters) {
    return '$volumes volumes · $chapters chapters';
  }

  @override
  String chapterMeta(String created, String modified, int wordCount) {
    return 'Created $created · Edited $modified · $wordCount words';
  }

  @override
  String get themeSlotLight => 'Light';

  @override
  String get themeSlotDark => 'Dark';

  @override
  String get themePresetsSubtitle =>
      'Tap to apply a palette to the current light or dark mode.';

  @override
  String get quickToolbarToolsTooltip => 'Tools';

  @override
  String get quickToolbarUndoTooltip => 'Undo';

  @override
  String get quickToolbarPasteTooltip => 'Paste';

  @override
  String get quickToolbarIndentTooltip => 'Indent';

  @override
  String get quickToolbarFormatTooltip => 'Format';

  @override
  String get quickToolbarSearchTooltip => 'Search';

  @override
  String get quickToolbarTimestampTooltip => 'Insert timestamp';

  @override
  String get quickToolbarBackupTooltip => 'Back up now';

  @override
  String get quickToolbarRestoreTooltip => 'Restore backup';

  @override
  String get quickToolbarEdit => 'Edit toolbar';

  @override
  String get quickToolbarEditHint =>
      'Long-press and drag on the toolbar to reorder. You can also drag here, or move tools between the fixed and custom zones.';

  @override
  String get quickToolbarPinnedSection => 'Fixed bar';

  @override
  String get quickToolbarCustomSection => 'Custom bar';

  @override
  String get quickToolbarAddSection => 'Add tool';

  @override
  String get quickToolbarSectionEmpty => 'No tools yet';

  @override
  String get quickToolbarAddPhrase => 'Quick phrase';

  @override
  String get quickToolbarPhraseName => 'Display name';

  @override
  String get quickToolbarPhraseContent => 'Inserted text';

  @override
  String get quickToolbarMoveToPinned => 'Move to fixed bar';

  @override
  String get quickToolbarMoveToCustom => 'Move to custom bar';

  @override
  String get quickToolbarDrawerEmpty => 'Nothing here yet';

  @override
  String get quickToolbarFormatApplyAll => 'Format document';

  @override
  String get quickToolbarFormatKeepParagraphBlanks =>
      'Keep blank lines between paragraphs';

  @override
  String get quickToolbarFormatRemoveParagraphBlanks =>
      'Remove blank lines between paragraphs';

  @override
  String get quickToolbarFormatInsertCjkLatinSpaces =>
      'Space between Chinese and English';

  @override
  String get quickToolbarFormatAddParagraphIndent => 'Indent paragraph starts';

  @override
  String get quickToolbarFormatRemoveParagraphIndent =>
      'Remove paragraph indents';

  @override
  String get quickToolbarFormatSimplifiedToTraditional =>
      'Simplified to Traditional Chinese';

  @override
  String get quickToolbarFormatTraditionalToSimplified =>
      'Traditional to Simplified Chinese';

  @override
  String get quickToolbarFormatHalfwidthToFullwidth =>
      'Halfwidth to fullwidth symbols';
}
