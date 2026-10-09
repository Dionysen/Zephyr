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
  String get platformDefaultFont => 'Platform default';

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
      'Settings for this section will arrive later.';

  @override
  String get settingsPlaceholderBody =>
      'This settings section is reserved for its own feature settings.';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionCloud => 'Cloud sync';

  @override
  String get settingsSectionEditor => 'Editor';

  @override
  String get settingsSectionShortcuts => 'Shortcuts';

  @override
  String get settingsSectionTheme => 'Theme';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get generalSectionTitle => 'General';

  @override
  String get immersiveStatusBarTitle => 'Immersive status bar';

  @override
  String get immersiveStatusBarSubtitle =>
      'Draw under a transparent status bar (chrome stays padded); text may scroll into that band.';

  @override
  String get hideStatusBarIconsTitle => 'Hide status bar icons';

  @override
  String get hideStatusBarIconsSubtitle =>
      'Only when immersive is on. Icons auto-hide; swipe from the edge to peek.';

  @override
  String get editorSectionTitle => 'Editor';

  @override
  String get editorSectionIntro =>
      'Typography and reading-column preferences apply immediately.';

  @override
  String get editorSectionFooter =>
      'Changes apply to the writing area immediately.';

  @override
  String get editorFontLabel => 'Font';

  @override
  String get editorFontDescription =>
      'Typeface used in the writing editor. Imports are shared with the UI font library.';

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
  String get appearanceSectionTitle => 'Appearance';

  @override
  String get appearanceSectionIntro =>
      'Choose a color palette, then tweak semantic colors if needed. Fonts, radius, and other chrome stay separate from themes.';

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
      'Typeface used by the writing shell chrome. Imports are shared with the editor font library.';

  @override
  String get uiFontSizeTitle => 'UI font size';

  @override
  String get uiFontSizeDescription =>
      'Size of sidebar, settings, and chrome text.';

  @override
  String get cornerRadiusTitle => 'Corner radius';

  @override
  String get cornerRadiusDescription =>
      'Shared roundness for buttons, menus, cards, and fields.';

  @override
  String get barCornerRadiusTitle => 'Bar corner radius';

  @override
  String get barCornerRadiusDescription =>
      'Roundness of the floating editor top bar and sidebar library dock.';

  @override
  String get showBordersTitle => 'Show borders';

  @override
  String get showBordersSubtitle =>
      'When off, controls have no outlines. When on, volumes and the library dock show borders.';

  @override
  String get sidebarItemInsetTitle => 'Sidebar item inset';

  @override
  String get sidebarItemInsetDescription =>
      'Equal left/right padding for volumes and chapters.';

  @override
  String get sidebarVolumeGapTitle => 'Sidebar volume spacing';

  @override
  String get sidebarVolumeGapDescription =>
      'Gap between volumes. Chapters stay flush with a 1px divider.';

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
      'Color presets only change the palette. Fonts, radius, and other chrome stay separate.';

  @override
  String get customColorsTitle => 'Custom colors';

  @override
  String get customColorsSubtitle =>
      'Adjust semantic colors for the current mode; changes apply immediately.';

  @override
  String get customizeTokensButton => 'Customize tokens';

  @override
  String get backToThemesButton => 'Back to themes';

  @override
  String get themeTokensTitle => 'Theme tokens';

  @override
  String get themeTokensIntro =>
      'Use a six-digit hexadecimal color. Changes apply immediately.';

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
  String get tokenEditorSurface => 'Editor surface';

  @override
  String get tokenSidebarSurface => 'Sidebar surface';

  @override
  String get tokenControlSurface => 'Control surface';

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
      'Background of side panels and chrome.';

  @override
  String get tokenControlSurfaceDescription =>
      'Fill color for fields, menus, and cards.';

  @override
  String get tokenBorderDescription => 'Hairlines around controls.';

  @override
  String get tokenDividerDescription => 'Sidebar chapter separators.';

  @override
  String get tokenPrimaryTextDescription =>
      'Default title and body copy color.';

  @override
  String get tokenMutedTextDescription =>
      'Dimmer copy used for setting hints and captions.';

  @override
  String get tokenAccentDescription =>
      'Interactive highlights and selected states.';

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
  String get librarySetupTitle => 'Choose a PureWriter library';

  @override
  String get librarySetupBody =>
      'Zephyr needs a library folder that contains App/Room.db. You can also start with a temporary library and switch later.';

  @override
  String get chooseLibraryDirectoryButton => 'Choose library folder';

  @override
  String get editorEmptyState => 'Choose or create a chapter to begin writing.';

  @override
  String get jumpToEnd => 'Jump to end';

  @override
  String get volumeInsertBelow => 'Insert volume below';

  @override
  String get chapterInsertBelow => 'Insert chapter below';

  @override
  String get actionMoveToVolume => 'Move to volume';

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
  String get tooltipCollapseAll => 'Collapse all';

  @override
  String get tooltipExpandAll => 'Expand all';

  @override
  String get tooltipReorder => 'Reorder';

  @override
  String get tooltipDoneReordering => 'Done reordering';

  @override
  String get tooltipOpenLibrary => 'Open library';

  @override
  String get tooltipOpenSidebar => 'Open sidebar';

  @override
  String get tooltipMore => 'More';

  @override
  String get tooltipEditBook => 'Edit book';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get selectBook => 'Select a book';

  @override
  String get moreSheetTitle => 'More';

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
}
