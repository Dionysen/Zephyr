import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Zephyr'**
  String get appTitle;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @untitledLibrary.
  ///
  /// In en, this message translates to:
  /// **'Untitled library'**
  String get untitledLibrary;

  /// No description provided for @temporaryLibraryName.
  ///
  /// In en, this message translates to:
  /// **'Temporary library'**
  String get temporaryLibraryName;

  /// No description provided for @platformDefaultFont.
  ///
  /// In en, this message translates to:
  /// **'Platform default'**
  String get platformDefaultFont;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @dropdownHintSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get dropdownHintSelect;

  /// No description provided for @dropdownNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get dropdownNoMatches;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App interface language.'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDesktopHeader.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsDesktopHeader;

  /// No description provided for @settingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearchHint;

  /// No description provided for @settingsBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsBackTooltip;

  /// No description provided for @settingsCustomColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get settingsCustomColorsTitle;

  /// No description provided for @settingsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsComingSoonTitle;

  /// No description provided for @settingsComingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings for this section will arrive later.'**
  String get settingsComingSoonSubtitle;

  /// No description provided for @settingsPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'This settings section is reserved for its own feature settings.'**
  String get settingsPlaceholderBody;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsSectionCloud;

  /// No description provided for @backupAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutoTitle;

  /// No description provided for @backupAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After edits, back up to Backups/Auto when leaving the app. Keeps the newest 25.'**
  String get backupAutoSubtitle;

  /// No description provided for @backupNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNowTitle;

  /// No description provided for @backupNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write a manual .pwb under Backups (not auto-pruned).'**
  String get backupNowSubtitle;

  /// No description provided for @backupNowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup completed.'**
  String get backupNowSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} backups available — overwrite or merge.'**
  String backupRestoreSubtitle(int count);

  /// No description provided for @backupRestoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No .pwb backups found.'**
  String get backupRestoreEmpty;

  /// No description provided for @backupRestoreModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore mode'**
  String get backupRestoreModeTitle;

  /// No description provided for @backupRestoreModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge (newer updateTime wins)'**
  String get backupRestoreModeMerge;

  /// No description provided for @backupRestoreModeOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite (replace the whole library)'**
  String get backupRestoreModeOverwrite;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm restore'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge the selected backup into the current library. A safety backup is created first.'**
  String get backupRestoreConfirmMerge;

  /// No description provided for @backupRestoreConfirmOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Replace the current library with the selected backup. A safety backup is created first.'**
  String get backupRestoreConfirmOverwrite;

  /// No description provided for @backupRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreAction;

  /// No description provided for @backupRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Library restored from backup.'**
  String get backupRestoreSuccess;

  /// No description provided for @backupKindAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get backupKindAuto;

  /// No description provided for @backupKindManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get backupKindManual;

  /// No description provided for @backupFooter.
  ///
  /// In en, this message translates to:
  /// **'Do not open the same library in Pure Writer at the same time. Backups are PureWriter-compatible .pwb files.'**
  String get backupFooter;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history revisions yet.'**
  String get historyEmpty;

  /// No description provided for @historyEmptyRevision.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get historyEmptyRevision;

  /// No description provided for @historyRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this revision?'**
  String get historyRestoreTitle;

  /// No description provided for @historyRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'The current chapter text will be replaced by this revision and recorded in History.'**
  String get historyRestoreBody;

  /// No description provided for @historyRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get historyRestoreAction;

  /// No description provided for @historyRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restored to the selected revision.'**
  String get historyRestoreSuccess;

  /// No description provided for @historyMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyMenuLabel;

  /// No description provided for @draftRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved draft found'**
  String get draftRecoverTitle;

  /// No description provided for @draftRecoverBody.
  ///
  /// In en, this message translates to:
  /// **'A draft newer than the library was found. Restore it?'**
  String get draftRecoverBody;

  /// No description provided for @draftRecoverAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get draftRecoverAction;

  /// No description provided for @draftDismissAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get draftDismissAction;

  /// No description provided for @settingsSectionEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get settingsSectionEditor;

  /// No description provided for @settingsSectionShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get settingsSectionShortcuts;

  /// No description provided for @shortcutsManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize shortcuts'**
  String get shortcutsManageTitle;

  /// No description provided for @shortcutsManageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and change key bindings'**
  String get shortcutsManageSubtitle;

  /// No description provided for @shortcutsResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all to defaults'**
  String get shortcutsResetAll;

  /// No description provided for @shortcutsResetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get shortcutsResetAction;

  /// No description provided for @shortcutsClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get shortcutsClearAction;

  /// No description provided for @shortcutsRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Press a new shortcut'**
  String get shortcutsRecordTitle;

  /// No description provided for @shortcutsRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Esc to cancel · Backspace to clear'**
  String get shortcutsRecordHint;

  /// No description provided for @shortcutsUnbound.
  ///
  /// In en, this message translates to:
  /// **'Unbound'**
  String get shortcutsUnbound;

  /// No description provided for @shortcutsConflictHint.
  ///
  /// In en, this message translates to:
  /// **'Conflicting shortcuts were replaced'**
  String get shortcutsConflictHint;

  /// No description provided for @shortcutGroupClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get shortcutGroupClipboard;

  /// No description provided for @shortcutGroupHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get shortcutGroupHistory;

  /// No description provided for @shortcutGroupDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get shortcutGroupDelete;

  /// No description provided for @shortcutGroupIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get shortcutGroupIndent;

  /// No description provided for @shortcutGroupNewline.
  ///
  /// In en, this message translates to:
  /// **'Newline'**
  String get shortcutGroupNewline;

  /// No description provided for @shortcutGroupNavigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get shortcutGroupNavigate;

  /// No description provided for @shortcutGroupSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get shortcutGroupSelect;

  /// No description provided for @shortcutGroupWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get shortcutGroupWorkspace;

  /// No description provided for @shortcutActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get shortcutActionCopy;

  /// No description provided for @shortcutActionCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get shortcutActionCut;

  /// No description provided for @shortcutActionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get shortcutActionPaste;

  /// No description provided for @shortcutActionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get shortcutActionSelectAll;

  /// No description provided for @shortcutActionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get shortcutActionUndo;

  /// No description provided for @shortcutActionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get shortcutActionRedo;

  /// No description provided for @shortcutActionDeleteBackward.
  ///
  /// In en, this message translates to:
  /// **'Delete backward'**
  String get shortcutActionDeleteBackward;

  /// No description provided for @shortcutActionDeleteForward.
  ///
  /// In en, this message translates to:
  /// **'Delete forward'**
  String get shortcutActionDeleteForward;

  /// No description provided for @shortcutActionDeleteWordBackward.
  ///
  /// In en, this message translates to:
  /// **'Delete word backward'**
  String get shortcutActionDeleteWordBackward;

  /// No description provided for @shortcutActionDeleteWordForward.
  ///
  /// In en, this message translates to:
  /// **'Delete word forward'**
  String get shortcutActionDeleteWordForward;

  /// No description provided for @shortcutActionIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get shortcutActionIndent;

  /// No description provided for @shortcutActionOutdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get shortcutActionOutdent;

  /// No description provided for @shortcutActionNewline.
  ///
  /// In en, this message translates to:
  /// **'Newline'**
  String get shortcutActionNewline;

  /// No description provided for @shortcutActionMoveLeft.
  ///
  /// In en, this message translates to:
  /// **'Move left'**
  String get shortcutActionMoveLeft;

  /// No description provided for @shortcutActionMoveRight.
  ///
  /// In en, this message translates to:
  /// **'Move right'**
  String get shortcutActionMoveRight;

  /// No description provided for @shortcutActionMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get shortcutActionMoveUp;

  /// No description provided for @shortcutActionMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get shortcutActionMoveDown;

  /// No description provided for @shortcutActionMoveWordLeft.
  ///
  /// In en, this message translates to:
  /// **'Move word left'**
  String get shortcutActionMoveWordLeft;

  /// No description provided for @shortcutActionMoveWordRight.
  ///
  /// In en, this message translates to:
  /// **'Move word right'**
  String get shortcutActionMoveWordRight;

  /// No description provided for @shortcutActionMoveLineStart.
  ///
  /// In en, this message translates to:
  /// **'Line start'**
  String get shortcutActionMoveLineStart;

  /// No description provided for @shortcutActionMoveLineEnd.
  ///
  /// In en, this message translates to:
  /// **'Line end'**
  String get shortcutActionMoveLineEnd;

  /// No description provided for @shortcutActionMovePageUp.
  ///
  /// In en, this message translates to:
  /// **'Page up'**
  String get shortcutActionMovePageUp;

  /// No description provided for @shortcutActionMovePageDown.
  ///
  /// In en, this message translates to:
  /// **'Page down'**
  String get shortcutActionMovePageDown;

  /// No description provided for @shortcutActionMoveDocumentStart.
  ///
  /// In en, this message translates to:
  /// **'Document start'**
  String get shortcutActionMoveDocumentStart;

  /// No description provided for @shortcutActionMoveDocumentEnd.
  ///
  /// In en, this message translates to:
  /// **'Document end'**
  String get shortcutActionMoveDocumentEnd;

  /// No description provided for @shortcutActionSelectLeft.
  ///
  /// In en, this message translates to:
  /// **'Select left'**
  String get shortcutActionSelectLeft;

  /// No description provided for @shortcutActionSelectRight.
  ///
  /// In en, this message translates to:
  /// **'Select right'**
  String get shortcutActionSelectRight;

  /// No description provided for @shortcutActionSelectUp.
  ///
  /// In en, this message translates to:
  /// **'Select up'**
  String get shortcutActionSelectUp;

  /// No description provided for @shortcutActionSelectDown.
  ///
  /// In en, this message translates to:
  /// **'Select down'**
  String get shortcutActionSelectDown;

  /// No description provided for @shortcutActionSelectWordLeft.
  ///
  /// In en, this message translates to:
  /// **'Select word left'**
  String get shortcutActionSelectWordLeft;

  /// No description provided for @shortcutActionSelectWordRight.
  ///
  /// In en, this message translates to:
  /// **'Select word right'**
  String get shortcutActionSelectWordRight;

  /// No description provided for @shortcutActionSelectLineStart.
  ///
  /// In en, this message translates to:
  /// **'Select to line start'**
  String get shortcutActionSelectLineStart;

  /// No description provided for @shortcutActionSelectLineEnd.
  ///
  /// In en, this message translates to:
  /// **'Select to line end'**
  String get shortcutActionSelectLineEnd;

  /// No description provided for @shortcutActionSelectPageUp.
  ///
  /// In en, this message translates to:
  /// **'Select page up'**
  String get shortcutActionSelectPageUp;

  /// No description provided for @shortcutActionSelectPageDown.
  ///
  /// In en, this message translates to:
  /// **'Select page down'**
  String get shortcutActionSelectPageDown;

  /// No description provided for @shortcutActionSelectDocumentStart.
  ///
  /// In en, this message translates to:
  /// **'Select to document start'**
  String get shortcutActionSelectDocumentStart;

  /// No description provided for @shortcutActionSelectDocumentEnd.
  ///
  /// In en, this message translates to:
  /// **'Select to document end'**
  String get shortcutActionSelectDocumentEnd;

  /// No description provided for @shortcutActionCloseSettings.
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get shortcutActionCloseSettings;

  /// No description provided for @settingsSectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsSectionTheme;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersionLabel(String version);

  /// No description provided for @aboutGitHubTitle.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get aboutGitHubTitle;

  /// No description provided for @aboutCheckUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get aboutCheckUpdatesTitle;

  /// No description provided for @aboutCheckUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch the latest release info from GitHub.'**
  String get aboutCheckUpdatesSubtitle;

  /// No description provided for @aboutCheckUpdatesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Update checks are coming soon.'**
  String get aboutCheckUpdatesComingSoon;

  /// No description provided for @aboutOpenLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get aboutOpenLinkFailed;

  /// No description provided for @generalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSectionTitle;

  /// No description provided for @immersiveStatusBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Immersive status bar'**
  String get immersiveStatusBarTitle;

  /// No description provided for @immersiveStatusBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Draw under a transparent status bar (chrome stays padded); text may scroll into that band.'**
  String get immersiveStatusBarSubtitle;

  /// No description provided for @hideStatusBarIconsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide status bar icons'**
  String get hideStatusBarIconsTitle;

  /// No description provided for @hideStatusBarIconsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only when immersive is on. Icons auto-hide; swipe from the edge to peek.'**
  String get hideStatusBarIconsSubtitle;

  /// No description provided for @hideQuickToolbarTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide quick input bar'**
  String get hideQuickToolbarTitle;

  /// No description provided for @hideQuickToolbarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When on, the accessory toolbar above the keyboard is hidden.'**
  String get hideQuickToolbarSubtitle;

  /// No description provided for @editorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorSectionTitle;

  /// No description provided for @editorSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Typography and reading-column preferences apply immediately.'**
  String get editorSectionIntro;

  /// No description provided for @editorSectionFooter.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to the writing area immediately.'**
  String get editorSectionFooter;

  /// No description provided for @editorFontLabel.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get editorFontLabel;

  /// No description provided for @editorFontDescription.
  ///
  /// In en, this message translates to:
  /// **'Typeface used in the writing editor. Imports are shared with the UI font library.'**
  String get editorFontDescription;

  /// No description provided for @editorFontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get editorFontSizeTitle;

  /// No description provided for @editorFontSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Size of the writing-column body text.'**
  String get editorFontSizeDescription;

  /// No description provided for @editorTitleSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Title size'**
  String get editorTitleSizeTitle;

  /// No description provided for @editorTitleSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Font size of the chapter title above the body.'**
  String get editorTitleSizeDescription;

  /// No description provided for @editorTitleCenteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Center title'**
  String get editorTitleCenteredTitle;

  /// No description provided for @editorTitleCenteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When on, center the title in the reading column; when off, align it to the body left edge.'**
  String get editorTitleCenteredSubtitle;

  /// No description provided for @editorLineHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Line height'**
  String get editorLineHeightTitle;

  /// No description provided for @editorLineHeightDescription.
  ///
  /// In en, this message translates to:
  /// **'Uniform line-height multiplier within a paragraph.'**
  String get editorLineHeightDescription;

  /// No description provided for @editorParagraphSpacingTitle.
  ///
  /// In en, this message translates to:
  /// **'Paragraph spacing'**
  String get editorParagraphSpacingTitle;

  /// No description provided for @editorParagraphSpacingDescription.
  ///
  /// In en, this message translates to:
  /// **'Gap between paragraphs, as a font-size multiplier.'**
  String get editorParagraphSpacingDescription;

  /// No description provided for @editorFirstLineIndentTitle.
  ///
  /// In en, this message translates to:
  /// **'First-line indent'**
  String get editorFirstLineIndentTitle;

  /// No description provided for @editorFirstLineIndentDescription.
  ///
  /// In en, this message translates to:
  /// **'Width inserted by Tab, and applied when opening chapters. Enter copies the previous paragraph\'s indent.'**
  String get editorFirstLineIndentDescription;

  /// No description provided for @editorMarginLeftTitle.
  ///
  /// In en, this message translates to:
  /// **'Left margin'**
  String get editorMarginLeftTitle;

  /// No description provided for @editorMarginLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'Left inset of the reading column. When space is tight, both margins shrink in proportion.'**
  String get editorMarginLeftDescription;

  /// No description provided for @editorMarginRightTitle.
  ///
  /// In en, this message translates to:
  /// **'Right margin'**
  String get editorMarginRightTitle;

  /// No description provided for @editorMarginRightDescription.
  ///
  /// In en, this message translates to:
  /// **'Right inset of the reading column. Equal values stay strictly symmetric.'**
  String get editorMarginRightDescription;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// No description provided for @appearanceSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a color palette, then tweak semantic colors if needed. Fonts, radius, and other chrome stay separate from themes.'**
  String get appearanceSectionIntro;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeTitle;

  /// No description provided for @themeModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose light, dark, or follow the system appearance.'**
  String get themeModeSubtitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @uiFontLabel.
  ///
  /// In en, this message translates to:
  /// **'UI font'**
  String get uiFontLabel;

  /// No description provided for @uiFontDescription.
  ///
  /// In en, this message translates to:
  /// **'Typeface used by the writing shell chrome. Imports are shared with the editor font library.'**
  String get uiFontDescription;

  /// No description provided for @uiFontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'UI font size'**
  String get uiFontSizeTitle;

  /// No description provided for @uiFontSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Size of sidebar, settings, and chrome text.'**
  String get uiFontSizeDescription;

  /// No description provided for @cornerRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get cornerRadiusTitle;

  /// No description provided for @cornerRadiusDescription.
  ///
  /// In en, this message translates to:
  /// **'Shared roundness for buttons, menus, cards, and fields.'**
  String get cornerRadiusDescription;

  /// No description provided for @barCornerRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Bar corner radius'**
  String get barCornerRadiusTitle;

  /// No description provided for @barCornerRadiusDescription.
  ///
  /// In en, this message translates to:
  /// **'Roundness of the floating editor top bar and sidebar library dock.'**
  String get barCornerRadiusDescription;

  /// No description provided for @showBordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Show borders'**
  String get showBordersTitle;

  /// No description provided for @showBordersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, controls have no outlines. When on, volumes and the library dock show borders.'**
  String get showBordersSubtitle;

  /// No description provided for @sidebarItemInsetTitle.
  ///
  /// In en, this message translates to:
  /// **'Sidebar item inset'**
  String get sidebarItemInsetTitle;

  /// No description provided for @sidebarItemInsetDescription.
  ///
  /// In en, this message translates to:
  /// **'Equal left/right padding for volumes and chapters.'**
  String get sidebarItemInsetDescription;

  /// No description provided for @sidebarVolumeGapTitle.
  ///
  /// In en, this message translates to:
  /// **'Sidebar volume spacing'**
  String get sidebarVolumeGapTitle;

  /// No description provided for @sidebarVolumeGapDescription.
  ///
  /// In en, this message translates to:
  /// **'Gap between volumes. Chapters stay flush with a 1px divider.'**
  String get sidebarVolumeGapDescription;

  /// No description provided for @themePresetsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get themePresetsSectionTitle;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @themePackRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename theme'**
  String get themePackRenameTitle;

  /// No description provided for @themePackCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String themePackCopyName(String name);

  /// No description provided for @themePackDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete theme?'**
  String get themePackDeleteTitle;

  /// No description provided for @themePackDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed permanently.'**
  String themePackDeleteBody(String name);

  /// No description provided for @themeCurrentCustom.
  ///
  /// In en, this message translates to:
  /// **'Current: Custom'**
  String get themeCurrentCustom;

  /// No description provided for @themeCurrentPreset.
  ///
  /// In en, this message translates to:
  /// **'Current: {preset}'**
  String themeCurrentPreset(String preset);

  /// No description provided for @themeCurrentCustomLong.
  ///
  /// In en, this message translates to:
  /// **'Current palette: Custom'**
  String get themeCurrentCustomLong;

  /// No description provided for @themeCurrentPresetLong.
  ///
  /// In en, this message translates to:
  /// **'Current palette: {preset}'**
  String themeCurrentPresetLong(String preset);

  /// No description provided for @themePresetsFooter.
  ///
  /// In en, this message translates to:
  /// **'Color presets only change the palette. Fonts, radius, and other chrome stay separate.'**
  String get themePresetsFooter;

  /// No description provided for @customColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get customColorsTitle;

  /// No description provided for @customColorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust semantic colors for the current mode; changes apply immediately.'**
  String get customColorsSubtitle;

  /// No description provided for @customizeTokensButton.
  ///
  /// In en, this message translates to:
  /// **'Customize tokens'**
  String get customizeTokensButton;

  /// No description provided for @backToThemesButton.
  ///
  /// In en, this message translates to:
  /// **'Back to themes'**
  String get backToThemesButton;

  /// No description provided for @themeTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme tokens'**
  String get themeTokensTitle;

  /// No description provided for @themeTokensIntro.
  ///
  /// In en, this message translates to:
  /// **'Use a six-digit hexadecimal color. Changes apply immediately.'**
  String get themeTokensIntro;

  /// No description provided for @restoreDefaultColors.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaultColors;

  /// No description provided for @saveAsThemeColor.
  ///
  /// In en, this message translates to:
  /// **'Save as theme'**
  String get saveAsThemeColor;

  /// No description provided for @saveThemeColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Save as theme color'**
  String get saveThemeColorTitle;

  /// No description provided for @saveThemeColorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme name'**
  String get saveThemeColorNameLabel;

  /// No description provided for @themePackNameDefault.
  ///
  /// In en, this message translates to:
  /// **'Theme {n}'**
  String themePackNameDefault(int n);

  /// No description provided for @themePresetLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themePresetLight;

  /// No description provided for @themePresetGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get themePresetGrey;

  /// No description provided for @themePresetSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get themePresetSlate;

  /// No description provided for @themePresetClaude.
  ///
  /// In en, this message translates to:
  /// **'Claude Code'**
  String get themePresetClaude;

  /// No description provided for @themePresetMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get themePresetMint;

  /// No description provided for @themePresetPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get themePresetPurple;

  /// No description provided for @themePresetHermes.
  ///
  /// In en, this message translates to:
  /// **'Hermes'**
  String get themePresetHermes;

  /// No description provided for @themePresetOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themePresetOcean;

  /// No description provided for @themePresetDarkModern.
  ///
  /// In en, this message translates to:
  /// **'Dark Modern'**
  String get themePresetDarkModern;

  /// No description provided for @tokenEditorSurface.
  ///
  /// In en, this message translates to:
  /// **'Editor surface'**
  String get tokenEditorSurface;

  /// No description provided for @tokenSidebarSurface.
  ///
  /// In en, this message translates to:
  /// **'Sidebar surface'**
  String get tokenSidebarSurface;

  /// No description provided for @tokenControlSurface.
  ///
  /// In en, this message translates to:
  /// **'Control surface'**
  String get tokenControlSurface;

  /// No description provided for @tokenBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get tokenBorder;

  /// No description provided for @tokenDivider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get tokenDivider;

  /// No description provided for @tokenPrimaryText.
  ///
  /// In en, this message translates to:
  /// **'Primary text'**
  String get tokenPrimaryText;

  /// No description provided for @tokenMutedText.
  ///
  /// In en, this message translates to:
  /// **'Muted text'**
  String get tokenMutedText;

  /// No description provided for @tokenAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get tokenAccent;

  /// No description provided for @tokenCursor.
  ///
  /// In en, this message translates to:
  /// **'Cursor'**
  String get tokenCursor;

  /// No description provided for @tokenEditorSurfaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Background of the writing column.'**
  String get tokenEditorSurfaceDescription;

  /// No description provided for @tokenSidebarSurfaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Background of side panels and chrome.'**
  String get tokenSidebarSurfaceDescription;

  /// No description provided for @tokenControlSurfaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill color for fields, menus, and cards.'**
  String get tokenControlSurfaceDescription;

  /// No description provided for @tokenBorderDescription.
  ///
  /// In en, this message translates to:
  /// **'Hairlines around controls.'**
  String get tokenBorderDescription;

  /// No description provided for @tokenDividerDescription.
  ///
  /// In en, this message translates to:
  /// **'Sidebar chapter separators.'**
  String get tokenDividerDescription;

  /// No description provided for @tokenPrimaryTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Default title and body copy color.'**
  String get tokenPrimaryTextDescription;

  /// No description provided for @tokenMutedTextDescription.
  ///
  /// In en, this message translates to:
  /// **'Dimmer copy used for setting hints and captions.'**
  String get tokenMutedTextDescription;

  /// No description provided for @tokenAccentDescription.
  ///
  /// In en, this message translates to:
  /// **'Interactive highlights and selected states.'**
  String get tokenAccentDescription;

  /// No description provided for @tokenCursorDescription.
  ///
  /// In en, this message translates to:
  /// **'Caret color in the writing editor.'**
  String get tokenCursorDescription;

  /// No description provided for @fontImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Font imported into the app library.'**
  String get fontImportSuccess;

  /// No description provided for @fontImportFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not import that font file.'**
  String get fontImportFailure;

  /// No description provided for @fontDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed from the app font library.'**
  String get fontDeleteSuccess;

  /// No description provided for @fontDeleteFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not delete that font.'**
  String get fontDeleteFailure;

  /// No description provided for @fontImportFromFile.
  ///
  /// In en, this message translates to:
  /// **'Choose font file…'**
  String get fontImportFromFile;

  /// No description provided for @fontDeleteFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Delete from library'**
  String get fontDeleteFromLibrary;

  /// No description provided for @fontDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete font?'**
  String get fontDeleteDialogTitle;

  /// No description provided for @fontDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Remove “{family}” from the app font library to free space?'**
  String fontDeleteDialogBody(String family);

  /// No description provided for @fontDeleteDialogBodyCompact.
  ///
  /// In en, this message translates to:
  /// **'Remove it from the app font library to free space?'**
  String get fontDeleteDialogBodyCompact;

  /// No description provided for @editorBackgroundSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor background'**
  String get editorBackgroundSectionTitle;

  /// No description provided for @editorBackgroundLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Light background'**
  String get editorBackgroundLightTitle;

  /// No description provided for @editorBackgroundDarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark background'**
  String get editorBackgroundDarkTitle;

  /// No description provided for @editorBackgroundNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get editorBackgroundNone;

  /// No description provided for @editorBackgroundCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get editorBackgroundCurrentBadge;

  /// No description provided for @editorBackgroundChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get editorBackgroundChoose;

  /// No description provided for @editorBackgroundClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get editorBackgroundClear;

  /// No description provided for @editorBackgroundSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose background'**
  String get editorBackgroundSelectTitle;

  /// No description provided for @editorBackgroundAddFromFile.
  ///
  /// In en, this message translates to:
  /// **'Add from file…'**
  String get editorBackgroundAddFromFile;

  /// No description provided for @editorBackgroundEmptyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No images yet. Tap above to add one.'**
  String get editorBackgroundEmptyLibrary;

  /// No description provided for @editorBackgroundNoImagePreview.
  ///
  /// In en, this message translates to:
  /// **'No background image'**
  String get editorBackgroundNoImagePreview;

  /// No description provided for @editorBackgroundPreviewSample.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog.\nWriting stays sharp above a soft backdrop.'**
  String get editorBackgroundPreviewSample;

  /// No description provided for @editorBackgroundFitTitle.
  ///
  /// In en, this message translates to:
  /// **'Image fit'**
  String get editorBackgroundFitTitle;

  /// No description provided for @editorBackgroundFitCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get editorBackgroundFitCover;

  /// No description provided for @editorBackgroundFitContain.
  ///
  /// In en, this message translates to:
  /// **'Contain'**
  String get editorBackgroundFitContain;

  /// No description provided for @editorBackgroundFitFill.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get editorBackgroundFitFill;

  /// No description provided for @editorBackgroundFitTile.
  ///
  /// In en, this message translates to:
  /// **'Tile'**
  String get editorBackgroundFitTile;

  /// No description provided for @editorBackgroundFitCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get editorBackgroundFitCenter;

  /// No description provided for @editorBackgroundOpacityTitle.
  ///
  /// In en, this message translates to:
  /// **'Background opacity'**
  String get editorBackgroundOpacityTitle;

  /// No description provided for @editorBackgroundBlurTitle.
  ///
  /// In en, this message translates to:
  /// **'Background blur'**
  String get editorBackgroundBlurTitle;

  /// No description provided for @editorBackgroundBlurDescription.
  ///
  /// In en, this message translates to:
  /// **'Gaussian blur on the image only; text stays sharp.'**
  String get editorBackgroundBlurDescription;

  /// No description provided for @editorBackgroundImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image added to the app library.'**
  String get editorBackgroundImportSuccess;

  /// No description provided for @editorBackgroundImportFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not import that image.'**
  String get editorBackgroundImportFailure;

  /// No description provided for @editorBackgroundDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Removed from the app library.'**
  String get editorBackgroundDeleteSuccess;

  /// No description provided for @editorBackgroundDeleteFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not delete that image.'**
  String get editorBackgroundDeleteFailure;

  /// No description provided for @editorBackgroundDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete image?'**
  String get editorBackgroundDeleteTitle;

  /// No description provided for @editorBackgroundDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”? Modes using it will reset to no background.'**
  String editorBackgroundDeleteBody(String name);

  /// No description provided for @editorBackgroundSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} · {fit} · {opacity}%'**
  String editorBackgroundSummary(String name, String fit, int opacity);

  /// No description provided for @editorBackgroundSummaryWithBlur.
  ///
  /// In en, this message translates to:
  /// **'{name} · {fit} · {opacity}% · blur {blur}'**
  String editorBackgroundSummaryWithBlur(
    String name,
    String fit,
    int opacity,
    int blur,
  );

  /// No description provided for @choiceDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get choiceDeleteTitle;

  /// No description provided for @choiceDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove this item?'**
  String get choiceDeleteBody;

  /// No description provided for @numberPickerDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default {value}'**
  String numberPickerDefaultLabel(String value);

  /// No description provided for @numberPickerRestoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore default ({value})'**
  String numberPickerRestoreDefault(String value);

  /// No description provided for @tempLibraryBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Using a temporary library'**
  String get tempLibraryBannerTitle;

  /// No description provided for @tempLibraryBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PureWriter library folder to open your work'**
  String get tempLibraryBannerSubtitle;

  /// No description provided for @chooseLibraryButton.
  ///
  /// In en, this message translates to:
  /// **'Choose library'**
  String get chooseLibraryButton;

  /// No description provided for @librarySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PureWriter library'**
  String get librarySetupTitle;

  /// No description provided for @librarySetupBody.
  ///
  /// In en, this message translates to:
  /// **'Zephyr needs a library folder that contains App/Room.db. You can also start with a temporary library and switch later.'**
  String get librarySetupBody;

  /// No description provided for @chooseLibraryDirectoryButton.
  ///
  /// In en, this message translates to:
  /// **'Choose library folder'**
  String get chooseLibraryDirectoryButton;

  /// No description provided for @editorEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Choose or create a chapter to begin writing.'**
  String get editorEmptyState;

  /// No description provided for @jumpToEnd.
  ///
  /// In en, this message translates to:
  /// **'Focus end'**
  String get jumpToEnd;

  /// No description provided for @volumeInsertBelow.
  ///
  /// In en, this message translates to:
  /// **'Insert volume below'**
  String get volumeInsertBelow;

  /// No description provided for @chapterInsertBelow.
  ///
  /// In en, this message translates to:
  /// **'Insert chapter below'**
  String get chapterInsertBelow;

  /// No description provided for @actionMoveToVolume.
  ///
  /// In en, this message translates to:
  /// **'Move to volume'**
  String get actionMoveToVolume;

  /// No description provided for @renameVolumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename volume'**
  String get renameVolumeTitle;

  /// No description provided for @renameChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename chapter'**
  String get renameChapterTitle;

  /// No description provided for @volumeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume name'**
  String get volumeNameLabel;

  /// No description provided for @chapterNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter name'**
  String get chapterNameLabel;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get validationNameRequired;

  /// No description provided for @deleteChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chapter'**
  String get deleteChapterTitle;

  /// No description provided for @deleteChapterBody.
  ///
  /// In en, this message translates to:
  /// **'Move “{name}” to the trash?'**
  String deleteChapterBody(String name);

  /// No description provided for @deleteVolumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete volume'**
  String get deleteVolumeTitle;

  /// No description provided for @deleteVolumeBody.
  ///
  /// In en, this message translates to:
  /// **'When deleting “{name}”, choose what to do with its chapters.'**
  String deleteVolumeBody(String name);

  /// No description provided for @deleteVolumeOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete volume only'**
  String get deleteVolumeOnly;

  /// No description provided for @deleteVolumeAndChapters.
  ///
  /// In en, this message translates to:
  /// **'Delete volume and chapters'**
  String get deleteVolumeAndChapters;

  /// No description provided for @moveToVolumeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to volume'**
  String get moveToVolumeSheetTitle;

  /// No description provided for @unfiledVolume.
  ///
  /// In en, this message translates to:
  /// **'Unfiled'**
  String get unfiledVolume;

  /// No description provided for @unfiledChaptersHeader.
  ///
  /// In en, this message translates to:
  /// **'Unfiled chapters'**
  String get unfiledChaptersHeader;

  /// No description provided for @tooltipHideSidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar'**
  String get tooltipHideSidebar;

  /// No description provided for @tooltipNewVolume.
  ///
  /// In en, this message translates to:
  /// **'New volume'**
  String get tooltipNewVolume;

  /// No description provided for @tooltipNewChapter.
  ///
  /// In en, this message translates to:
  /// **'New chapter'**
  String get tooltipNewChapter;

  /// No description provided for @tooltipCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get tooltipCollapseAll;

  /// No description provided for @tooltipExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get tooltipExpandAll;

  /// No description provided for @tooltipReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get tooltipReorder;

  /// No description provided for @tooltipDoneReordering.
  ///
  /// In en, this message translates to:
  /// **'Done reordering'**
  String get tooltipDoneReordering;

  /// No description provided for @tooltipOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open library'**
  String get tooltipOpenLibrary;

  /// No description provided for @tooltipOpenSidebar.
  ///
  /// In en, this message translates to:
  /// **'Open sidebar'**
  String get tooltipOpenSidebar;

  /// No description provided for @tooltipMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tooltipMore;

  /// No description provided for @tooltipEditBook.
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get tooltipEditBook;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select a book'**
  String get selectBook;

  /// No description provided for @moreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreSheetTitle;

  /// No description provided for @noMobileTools.
  ///
  /// In en, this message translates to:
  /// **'No tools available'**
  String get noMobileTools;

  /// No description provided for @editBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit book'**
  String get editBookTitle;

  /// No description provided for @bookNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Book title'**
  String get bookNameLabel;

  /// No description provided for @bookNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a book title'**
  String get bookNameHint;

  /// No description provided for @bookNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a book title'**
  String get bookNameRequired;

  /// No description provided for @bookTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get bookTagsLabel;

  /// No description provided for @bookTagsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Literature'**
  String get bookTagsHint;

  /// No description provided for @bookDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bookDescriptionLabel;

  /// No description provided for @bookDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Briefly describe this book'**
  String get bookDescriptionHint;

  /// No description provided for @bookStatsMeta.
  ///
  /// In en, this message translates to:
  /// **'{volumes} volumes · {chapters} chapters'**
  String bookStatsMeta(int volumes, int chapters);

  /// No description provided for @chapterMeta.
  ///
  /// In en, this message translates to:
  /// **'Created {created} · Edited {modified} · {wordCount} words'**
  String chapterMeta(String created, String modified, int wordCount);

  /// No description provided for @themeSlotLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeSlotLight;

  /// No description provided for @themeSlotDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeSlotDark;

  /// No description provided for @themePresetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to apply a palette to the current light or dark mode.'**
  String get themePresetsSubtitle;

  /// No description provided for @quickToolbarToolsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get quickToolbarToolsTooltip;

  /// No description provided for @quickToolbarUndoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get quickToolbarUndoTooltip;

  /// No description provided for @quickToolbarPasteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get quickToolbarPasteTooltip;

  /// No description provided for @quickToolbarIndentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get quickToolbarIndentTooltip;

  /// No description provided for @quickToolbarFormatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get quickToolbarFormatTooltip;

  /// No description provided for @quickToolbarEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit toolbar'**
  String get quickToolbarEdit;

  /// No description provided for @quickToolbarEditHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder, or move tools between the fixed and custom zones.'**
  String get quickToolbarEditHint;

  /// No description provided for @quickToolbarPinnedSection.
  ///
  /// In en, this message translates to:
  /// **'Fixed bar'**
  String get quickToolbarPinnedSection;

  /// No description provided for @quickToolbarCustomSection.
  ///
  /// In en, this message translates to:
  /// **'Custom bar'**
  String get quickToolbarCustomSection;

  /// No description provided for @quickToolbarAddSection.
  ///
  /// In en, this message translates to:
  /// **'Add tool'**
  String get quickToolbarAddSection;

  /// No description provided for @quickToolbarSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tools yet'**
  String get quickToolbarSectionEmpty;

  /// No description provided for @quickToolbarAddPhrase.
  ///
  /// In en, this message translates to:
  /// **'Quick phrase'**
  String get quickToolbarAddPhrase;

  /// No description provided for @quickToolbarPhraseName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get quickToolbarPhraseName;

  /// No description provided for @quickToolbarPhraseContent.
  ///
  /// In en, this message translates to:
  /// **'Inserted text'**
  String get quickToolbarPhraseContent;

  /// No description provided for @quickToolbarMoveToPinned.
  ///
  /// In en, this message translates to:
  /// **'Move to fixed bar'**
  String get quickToolbarMoveToPinned;

  /// No description provided for @quickToolbarMoveToCustom.
  ///
  /// In en, this message translates to:
  /// **'Move to custom bar'**
  String get quickToolbarMoveToCustom;

  /// No description provided for @quickToolbarDrawerEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tool panel content coming soon'**
  String get quickToolbarDrawerEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
