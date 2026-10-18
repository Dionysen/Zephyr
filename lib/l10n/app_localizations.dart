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
  /// **'LXGW WenKai (default)'**
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
  /// **'These options are still being prepared.'**
  String get settingsComingSoonSubtitle;

  /// No description provided for @settingsPlaceholderBody.
  ///
  /// In en, this message translates to:
  /// **'Related options will appear here later.'**
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

  /// No description provided for @backupGroupLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local backup'**
  String get backupGroupLocalTitle;

  /// No description provided for @backupGroupCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get backupGroupCloudTitle;

  /// No description provided for @cloudSyncSubtitleSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Connect Nutstore WebDAV for cloud backup and sync'**
  String get cloudSyncSubtitleSignedOut;

  /// No description provided for @cloudSyncSubtitleSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String cloudSyncSubtitleSignedIn(String name);

  /// No description provided for @cloudBackupQuickTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get cloudBackupQuickTooltip;

  /// No description provided for @cloudBackupQuickTooltipUnconfigured.
  ///
  /// In en, this message translates to:
  /// **'Connect Nutstore for cloud backup'**
  String get cloudBackupQuickTooltipUnconfigured;

  /// No description provided for @cloudSyncEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable cloud backup'**
  String get cloudSyncEnableTitle;

  /// No description provided for @cloudSyncEnableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload local backups to Nutstore on exit or after mobile backgrounding with edits'**
  String get cloudSyncEnableSubtitle;

  /// No description provided for @cloudSyncLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Nutstore'**
  String get cloudSyncLoginTitle;

  /// No description provided for @cloudSyncLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account, WebDAV URL, and app password'**
  String get cloudSyncLoginSubtitle;

  /// No description provided for @cloudSyncSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutstore settings'**
  String get cloudSyncSettingsTitle;

  /// No description provided for @cloudSyncSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String cloudSyncSettingsSubtitle(String name);

  /// No description provided for @cloudSyncUnbindTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get cloudSyncUnbindTitle;

  /// No description provided for @cloudSyncLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get cloudSyncLogoutTitle;

  /// No description provided for @cloudSyncLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stops cloud backup'**
  String get cloudSyncLogoutSubtitle;

  /// No description provided for @cloudSyncBackupNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up to cloud now'**
  String get cloudSyncBackupNowTitle;

  /// No description provided for @cloudSyncBackupNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a backup on this device, then upload it to the Zephyr folder on Nutstore'**
  String get cloudSyncBackupNowSubtitle;

  /// No description provided for @cloudSyncBackupNowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup completed.'**
  String get cloudSyncBackupNowSuccess;

  /// No description provided for @cloudSyncRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud'**
  String get cloudSyncRestoreTitle;

  /// No description provided for @cloudSyncRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a backup from Nutstore — overwrite or merge'**
  String get cloudSyncRestoreSubtitle;

  /// No description provided for @cloudSyncRestoreEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cloud backups found.'**
  String get cloudSyncRestoreEmpty;

  /// No description provided for @cloudSyncLatestSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest cloud backup'**
  String get cloudSyncLatestSnapshotTitle;

  /// No description provided for @cloudSyncLatestSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current snapshot on Nutstore'**
  String get cloudSyncLatestSnapshotSubtitle;

  /// No description provided for @cloudSyncRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Library restored from cloud backup.'**
  String get cloudSyncRestoreSuccess;

  /// No description provided for @cloudSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync failed: {error}'**
  String cloudSyncFailed(String error);

  /// No description provided for @cloudSyncAnotherLibrary.
  ///
  /// In en, this message translates to:
  /// **'This Zephyr cloud folder belongs to another library. Choose the original local directory or another WebDAV account; cloud sync has stopped.'**
  String get cloudSyncAnotherLibrary;

  /// No description provided for @cloudSyncMissingManifest.
  ///
  /// In en, this message translates to:
  /// **'The Zephyr folder in the cloud looks incomplete. Sort it out before syncing again.'**
  String get cloudSyncMissingManifest;

  /// No description provided for @cloudSyncWaitBeforeChoosingDirectory.
  ///
  /// In en, this message translates to:
  /// **'Wait for cloud sync to finish before choosing another directory.'**
  String get cloudSyncWaitBeforeChoosingDirectory;

  /// No description provided for @cloudSyncCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Nutstore WebDAV'**
  String get cloudSyncCredentialsTitle;

  /// No description provided for @cloudSyncCredentialsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutstore settings'**
  String get cloudSyncCredentialsEditTitle;

  /// No description provided for @cloudSyncCredentialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a Nutstore app password, not your account password. Stored securely on this device.'**
  String get cloudSyncCredentialsSubtitle;

  /// No description provided for @cloudSyncCredentialsPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep the current app password'**
  String get cloudSyncCredentialsPasswordHint;

  /// No description provided for @cloudSyncCredentialsSave.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get cloudSyncCredentialsSave;

  /// No description provided for @cloudSyncCredentialsSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cloudSyncCredentialsSaveEdit;

  /// No description provided for @cloudSyncCredentialsSaved.
  ///
  /// In en, this message translates to:
  /// **'Nutstore connected'**
  String get cloudSyncCredentialsSaved;

  /// No description provided for @cloudSyncCredentialsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nutstore settings saved'**
  String get cloudSyncCredentialsUpdated;

  /// No description provided for @cloudSyncClientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutstore account'**
  String get cloudSyncClientIdLabel;

  /// No description provided for @cloudSyncServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL'**
  String get cloudSyncServerUrlLabel;

  /// No description provided for @cloudSyncClientSecretLabel.
  ///
  /// In en, this message translates to:
  /// **'App password'**
  String get cloudSyncClientSecretLabel;

  /// No description provided for @backupAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get backupAutoTitle;

  /// No description provided for @backupAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Back up edited content hourly, and on mobile backgrounding. Keep the latest 25 local backups.'**
  String get backupAutoSubtitle;

  /// No description provided for @backupNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNowTitle;

  /// No description provided for @backupNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a manual backup now. Manual and automatic backups together keep the latest 25.'**
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

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving failed. Your edits remain open; retry before exiting: {error}'**
  String saveFailed(String error);

  /// No description provided for @exitBackupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get exitBackupInProgress;

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
  /// **'No backup files found.'**
  String get backupRestoreEmpty;

  /// No description provided for @backupRestoreModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore mode'**
  String get backupRestoreModeTitle;

  /// No description provided for @backupRestoreModeMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge (keep the newer version)'**
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

  /// No description provided for @backupMergeResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge complete'**
  String get backupMergeResultTitle;

  /// No description provided for @backupMergeResultSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get backupMergeResultSeparator;

  /// No description provided for @backupMergeResultNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Merge complete. No chapter changes.'**
  String get backupMergeResultNoChanges;

  /// No description provided for @backupMergeResultAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count}'**
  String backupMergeResultAdded(int count);

  /// No description provided for @backupMergeResultUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {count}'**
  String backupMergeResultUpdated(int count);

  /// No description provided for @backupMergeResultRemoved.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count}'**
  String backupMergeResultRemoved(int count);

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
  /// **'Don\'t open the same library in Pure Writer at the same time. Backup files can be opened in Pure Writer.'**
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

  /// No description provided for @shortcutActionCloudBackupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up to cloud now'**
  String get shortcutActionCloudBackupNow;

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

  /// No description provided for @settingsSectionAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get settingsSectionAi;

  /// No description provided for @aboutSettingsListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, updates, and links'**
  String get aboutSettingsListSubtitle;

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
  /// **'The app extends under a transparent status bar, and text can scroll into that area.'**
  String get immersiveStatusBarSubtitle;

  /// No description provided for @hideStatusBarIconsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide status bar icons'**
  String get hideStatusBarIconsTitle;

  /// No description provided for @hideStatusBarIconsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only while the immersive status bar is on. Icons hide on their own; swipe from the edge to show them briefly.'**
  String get hideStatusBarIconsSubtitle;

  /// No description provided for @mobileBehaviorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileBehaviorSectionTitle;

  /// No description provided for @mobileBehaviorSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to phones and tablets.'**
  String get mobileBehaviorSectionSubtitle;

  /// No description provided for @scrollToHideMobileTopBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide top bar while scrolling'**
  String get scrollToHideMobileTopBarTitle;

  /// No description provided for @scrollToHideMobileTopBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collapse the floating book bar when scrolling down; show it when scrolling up.'**
  String get scrollToHideMobileTopBarSubtitle;

  /// No description provided for @openSidebarAfterBookSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Open chapter list after switching books'**
  String get openSidebarAfterBookSwitchTitle;

  /// No description provided for @openSidebarAfterBookSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the chapter list after you pick another book.'**
  String get openSidebarAfterBookSwitchSubtitle;

  /// No description provided for @keepScreenOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get keepScreenOnTitle;

  /// No description provided for @keepScreenOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent the display from sleeping while the app is open.'**
  String get keepScreenOnSubtitle;

  /// No description provided for @doubleBackToExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Press back twice to exit'**
  String get doubleBackToExitTitle;

  /// No description provided for @doubleBackToExitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, a single back press exits the app.'**
  String get doubleBackToExitSubtitle;

  /// No description provided for @openBookListOnStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Open book list on launch'**
  String get openBookListOnStartupTitle;

  /// No description provided for @openBookListOnStartupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the book picker when the workspace opens.'**
  String get openBookListOnStartupSubtitle;

  /// No description provided for @openSidebarOnStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Open chapter list on launch'**
  String get openSidebarOnStartupTitle;

  /// No description provided for @openSidebarOnStartupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the chapter list when the workspace opens.'**
  String get openSidebarOnStartupSubtitle;

  /// No description provided for @desktopBehaviorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Desktop workspace'**
  String get desktopBehaviorSectionTitle;

  /// No description provided for @desktopBehaviorSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies to the desktop writing layout.'**
  String get desktopBehaviorSectionSubtitle;

  /// No description provided for @desktopFloatingSidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Floating sidebar on hover'**
  String get desktopFloatingSidebarTitle;

  /// No description provided for @desktopFloatingSidebarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Move the pointer to the left screen edge to show the chapter list over the editor; hides when the pointer leaves.'**
  String get desktopFloatingSidebarSubtitle;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @aiFeaturesEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get aiFeaturesEnabledTitle;

  /// No description provided for @aiFeaturesEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, the AI button is hidden in the workspace and any open assistant returns to the book.'**
  String get aiFeaturesEnabledSubtitle;

  /// No description provided for @hideAiAssistantAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide assistant avatar'**
  String get hideAiAssistantAvatarTitle;

  /// No description provided for @hideAiAssistantAvatarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide the avatar so chat bubbles line up on both sides.'**
  String get hideAiAssistantAvatarSubtitle;

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

  /// No description provided for @showChapterDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show chapter details'**
  String get showChapterDetailsTitle;

  /// No description provided for @showChapterDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, the sidebar shows chapter titles only.'**
  String get showChapterDetailsSubtitle;

  /// No description provided for @editorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorSectionTitle;

  /// No description provided for @editorSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Font and layout preferences apply right away.'**
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
  /// **'Font used while writing. Imported fonts can also be used in the interface.'**
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

  /// No description provided for @editorTypewriterModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Typewriter mode'**
  String get editorTypewriterModeTitle;

  /// No description provided for @editorTypewriterModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keeps the editing line centered; dims other paragraphs and the unfocused title.'**
  String get editorTypewriterModeSubtitle;

  /// No description provided for @editorJumpToEndOnScrollDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus end while scrolling'**
  String get editorJumpToEndOnScrollDownTitle;

  /// No description provided for @editorJumpToEndOnScrollDownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When on, shows the focus-end button while scrolling down; hides at the bottom or when scrolling up.'**
  String get editorJumpToEndOnScrollDownSubtitle;

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

  /// No description provided for @editorWidthTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor width'**
  String get editorWidthTitle;

  /// No description provided for @editorWidthDescription.
  ///
  /// In en, this message translates to:
  /// **'Width of the text column, always centered. It narrows when the window is too small.'**
  String get editorWidthDescription;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// No description provided for @appearanceSectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a palette, or adjust individual colors. Fonts and corner radius stay as you set them.'**
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
  /// **'Font used for the sidebar, settings, and other interface text. Imported fonts can also be used while writing.'**
  String get uiFontDescription;

  /// No description provided for @uiFontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'UI font size'**
  String get uiFontSizeTitle;

  /// No description provided for @uiFontSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Size of text in the sidebar, settings, and the rest of the interface.'**
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
  /// **'Roundness of the editor top bar and the bar at the bottom of the sidebar.'**
  String get barCornerRadiusDescription;

  /// No description provided for @chatBubbleCornerRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat bubble corners'**
  String get chatBubbleCornerRadiusTitle;

  /// No description provided for @chatBubbleCornerRadiusDescription.
  ///
  /// In en, this message translates to:
  /// **'Roundness of AI chat bubbles. The outer top corner stays square.'**
  String get chatBubbleCornerRadiusDescription;

  /// No description provided for @showBordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Show borders'**
  String get showBordersTitle;

  /// No description provided for @showBordersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When off, buttons and cards have no outline. When on, volumes and the library bar show a border.'**
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

  /// No description provided for @sidebarItemCornerRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Sidebar volume & chapter corners'**
  String get sidebarItemCornerRadiusTitle;

  /// No description provided for @sidebarItemCornerRadiusDescription.
  ///
  /// In en, this message translates to:
  /// **'Corner radius for volume headers and chapter rows in the library sidebar.'**
  String get sidebarItemCornerRadiusDescription;

  /// No description provided for @sidebarVolumeGapTitle.
  ///
  /// In en, this message translates to:
  /// **'Sidebar volume spacing'**
  String get sidebarVolumeGapTitle;

  /// No description provided for @sidebarVolumeGapDescription.
  ///
  /// In en, this message translates to:
  /// **'Space between volumes. Chapters stay close, separated by a line.'**
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
  /// **'Palettes only change colors. Fonts, corners, and other layout stay as you set them.'**
  String get themePresetsFooter;

  /// No description provided for @customColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get customColorsTitle;

  /// No description provided for @customColorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust colors for the current appearance. Changes apply right away.'**
  String get customColorsSubtitle;

  /// No description provided for @customizeTokensButton.
  ///
  /// In en, this message translates to:
  /// **'Customize colors'**
  String get customizeTokensButton;

  /// No description provided for @backToThemesButton.
  ///
  /// In en, this message translates to:
  /// **'Back to themes'**
  String get backToThemesButton;

  /// No description provided for @themeTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get themeTokensTitle;

  /// No description provided for @themeTokensIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter a color code such as #336699. Changes apply right away.'**
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
  /// **'Writing background'**
  String get tokenEditorSurface;

  /// No description provided for @tokenSidebarSurface.
  ///
  /// In en, this message translates to:
  /// **'Sidebar background'**
  String get tokenSidebarSurface;

  /// No description provided for @tokenControlSurface.
  ///
  /// In en, this message translates to:
  /// **'Buttons and fields'**
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
  /// **'Background of the sidebar and surrounding panels.'**
  String get tokenSidebarSurfaceDescription;

  /// No description provided for @tokenControlSurfaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill color for fields, menus, and cards.'**
  String get tokenControlSurfaceDescription;

  /// No description provided for @tokenBorderDescription.
  ///
  /// In en, this message translates to:
  /// **'Outlines around buttons and fields.'**
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
  /// **'Softer color for hints and captions.'**
  String get tokenMutedTextDescription;

  /// No description provided for @tokenAccentDescription.
  ///
  /// In en, this message translates to:
  /// **'Highlights and selected items.'**
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
  /// **'Editor background image'**
  String get editorBackgroundSectionTitle;

  /// No description provided for @editorBackgroundEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Use background image'**
  String get editorBackgroundEnabledTitle;

  /// No description provided for @editorBackgroundEnabledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide without clearing your picks'**
  String get editorBackgroundEnabledSubtitle;

  /// No description provided for @themeColorsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get themeColorsSectionTitle;

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
  /// **'Softens the image only. Text stays sharp.'**
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
  /// **'Welcome to Zephyr'**
  String get librarySetupTitle;

  /// No description provided for @librarySetupBody.
  ///
  /// In en, this message translates to:
  /// **'Start writing in a local temporary library, or connect an existing PureWriter folder when you are ready.'**
  String get librarySetupBody;

  /// No description provided for @startTemporaryLibraryButton.
  ///
  /// In en, this message translates to:
  /// **'Start writing'**
  String get startTemporaryLibraryButton;

  /// No description provided for @libraryLoadFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Could not open the last library. Start fresh or choose another folder.'**
  String get libraryLoadFailedHint;

  /// No description provided for @libraryRecoveredToTemporary.
  ///
  /// In en, this message translates to:
  /// **'Opened the temporary library instead. You can reconnect your PureWriter folder from the banner.'**
  String get libraryRecoveredToTemporary;

  /// No description provided for @chooseLibraryDirectoryButton.
  ///
  /// In en, this message translates to:
  /// **'Choose PureWriter folder'**
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

  /// No description provided for @volumeAppendChapter.
  ///
  /// In en, this message translates to:
  /// **'Insert chapter at end of volume'**
  String get volumeAppendChapter;

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

  /// No description provided for @actionMoveToBook.
  ///
  /// In en, this message translates to:
  /// **'Move to book'**
  String get actionMoveToBook;

  /// No description provided for @actionConvertVolumeToBook.
  ///
  /// In en, this message translates to:
  /// **'Convert this volume to a book'**
  String get actionConvertVolumeToBook;

  /// No description provided for @moveToBookSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to book'**
  String get moveToBookSheetTitle;

  /// No description provided for @moveToBookNoTargets.
  ///
  /// In en, this message translates to:
  /// **'There are no other books to move into.'**
  String get moveToBookNoTargets;

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

  /// No description provided for @tooltipAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tooltipAdd;

  /// No description provided for @tooltipSearchChapters.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tooltipSearchChapters;

  /// No description provided for @searchSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchSheetTitle;

  /// No description provided for @searchSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles and content'**
  String get searchSheetHint;

  /// No description provided for @searchSheetEmptyQuery.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to search.'**
  String get searchSheetEmptyQuery;

  /// No description provided for @searchSheetNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results.'**
  String get searchSheetNoResults;

  /// No description provided for @searchScopeArticle.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get searchScopeArticle;

  /// No description provided for @searchScopeVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get searchScopeVolume;

  /// No description provided for @searchScopeBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get searchScopeBook;

  /// No description provided for @searchScopeAllBooks.
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get searchScopeAllBooks;

  /// No description provided for @tooltipLocateCurrentChapter.
  ///
  /// In en, this message translates to:
  /// **'Locate current chapter'**
  String get tooltipLocateCurrentChapter;

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
  /// **'Sort order'**
  String get tooltipReorder;

  /// No description provided for @tooltipDoneReordering.
  ///
  /// In en, this message translates to:
  /// **'Done adjusting order'**
  String get tooltipDoneReordering;

  /// No description provided for @chapterSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual order'**
  String get chapterSortManual;

  /// No description provided for @chapterSortAdjustOrder.
  ///
  /// In en, this message translates to:
  /// **'Adjust order'**
  String get chapterSortAdjustOrder;

  /// No description provided for @chapterSortCreatedAsc.
  ///
  /// In en, this message translates to:
  /// **'Created · Oldest first'**
  String get chapterSortCreatedAsc;

  /// No description provided for @chapterSortCreatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Created · Newest first'**
  String get chapterSortCreatedDesc;

  /// No description provided for @chapterSortUpdatedAsc.
  ///
  /// In en, this message translates to:
  /// **'Modified · Oldest first'**
  String get chapterSortUpdatedAsc;

  /// No description provided for @chapterSortUpdatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Modified · Newest first'**
  String get chapterSortUpdatedDesc;

  /// No description provided for @chapterSortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Name · A→Z'**
  String get chapterSortTitleAsc;

  /// No description provided for @chapterSortTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Name · Z→A'**
  String get chapterSortTitleDesc;

  /// No description provided for @tooltipAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get tooltipAiAssistant;

  /// No description provided for @aiChatWelcome.
  ///
  /// In en, this message translates to:
  /// **'Tell me what you\'re working on.'**
  String get aiChatWelcome;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get aiChatInputHint;

  /// No description provided for @aiChatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiChatSend;

  /// No description provided for @aiChatStopGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get aiChatStopGenerating;

  /// No description provided for @aiContextRemoveArticle.
  ///
  /// In en, this message translates to:
  /// **'Remove from context'**
  String get aiContextRemoveArticle;

  /// No description provided for @llmSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI models'**
  String get llmSettingsTitle;

  /// No description provided for @llmSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provider, API key, and model'**
  String get llmSettingsSubtitle;

  /// No description provided for @llmSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Your key stays on this device. Other settings are included in backups.'**
  String get llmSettingsIntro;

  /// No description provided for @llmBehaviorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat behavior'**
  String get llmBehaviorSectionTitle;

  /// No description provided for @llmStreamOutputTitle.
  ///
  /// In en, this message translates to:
  /// **'Streaming output'**
  String get llmStreamOutputTitle;

  /// No description provided for @llmStreamOutputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the reply as it is written'**
  String get llmStreamOutputSubtitle;

  /// No description provided for @llmAllowThinkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow thinking'**
  String get llmAllowThinkingTitle;

  /// No description provided for @llmAllowThinkingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let models that can reason think before they answer'**
  String get llmAllowThinkingSubtitle;

  /// No description provided for @llmPresetPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset prompt'**
  String get llmPresetPromptTitle;

  /// No description provided for @llmPresetPromptDescription.
  ///
  /// In en, this message translates to:
  /// **'Sent as system instructions on every chat—use it for genre, tone, POV, and other standing preferences.'**
  String get llmPresetPromptDescription;

  /// No description provided for @llmPresetPromptHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. You are a writing assistant. Reply concisely; when continuing prose, match POV, tense, and voice.'**
  String get llmPresetPromptHint;

  /// No description provided for @llmMaxInputTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Context limit (input)'**
  String get llmMaxInputTokensTitle;

  /// No description provided for @llmMaxInputTokensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Older messages are shortened once this limit is reached'**
  String get llmMaxInputTokensSubtitle;

  /// No description provided for @llmMaxOutputTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply limit (output)'**
  String get llmMaxOutputTokensTitle;

  /// No description provided for @llmMaxOutputTokensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long a single reply can be'**
  String get llmMaxOutputTokensSubtitle;

  /// No description provided for @llmThinkingLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Thinking intensity'**
  String get llmThinkingLevelTitle;

  /// No description provided for @llmThinkingLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deeper thinking usually takes longer'**
  String get llmThinkingLevelSubtitle;

  /// No description provided for @llmDefaultThinkingLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Default thinking intensity'**
  String get llmDefaultThinkingLevelTitle;

  /// No description provided for @llmDefaultThinkingLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starting level for new chats. You can change it beside the message box.'**
  String get llmDefaultThinkingLevelSubtitle;

  /// No description provided for @llmThinkingDisabledInSettings.
  ///
  /// In en, this message translates to:
  /// **'Turn on “Allow thinking” in AI model settings first'**
  String get llmThinkingDisabledInSettings;

  /// No description provided for @llmThinkingOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get llmThinkingOff;

  /// No description provided for @llmThinkingMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get llmThinkingMinimal;

  /// No description provided for @llmThinkingLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get llmThinkingLow;

  /// No description provided for @llmThinkingMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get llmThinkingMedium;

  /// No description provided for @llmThinkingHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get llmThinkingHigh;

  /// No description provided for @llmThinkingAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get llmThinkingAuto;

  /// No description provided for @aiChatAiSettingsEntry.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiChatAiSettingsEntry;

  /// No description provided for @aiChatSessionOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat options'**
  String get aiChatSessionOptionsTitle;

  /// No description provided for @aiChatSessionProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiChatSessionProviderTitle;

  /// No description provided for @aiChatSessionProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a vendor you configured in AI settings'**
  String get aiChatSessionProviderSubtitle;

  /// No description provided for @aiChatSessionOptionsNeedTest.
  ///
  /// In en, this message translates to:
  /// **'Run a connection test in AI model settings first.'**
  String get aiChatSessionOptionsNeedTest;

  /// No description provided for @aiChatSessionModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Override the default model from settings'**
  String get aiChatSessionModelSubtitle;

  /// No description provided for @aiChatThinkingForModel.
  ///
  /// In en, this message translates to:
  /// **'Model: {model}'**
  String aiChatThinkingForModel(String model);

  /// No description provided for @aiChatSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get aiChatSessionsTitle;

  /// No description provided for @aiChatSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch, archive, or delete saved chats for this chapter'**
  String get aiChatSessionsSubtitle;

  /// No description provided for @aiChatNewSession.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get aiChatNewSession;

  /// No description provided for @aiChatShowArchivedSessions.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get aiChatShowArchivedSessions;

  /// No description provided for @aiChatNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet.'**
  String get aiChatNoSessions;

  /// No description provided for @aiChatSessionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String aiChatSessionUpdated(String time);

  /// No description provided for @aiChatOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get aiChatOpenSession;

  /// No description provided for @aiChatArchiveSession.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get aiChatArchiveSession;

  /// No description provided for @aiChatUnarchiveSession.
  ///
  /// In en, this message translates to:
  /// **'Restore from archive'**
  String get aiChatUnarchiveSession;

  /// No description provided for @aiChatDeleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get aiChatDeleteSession;

  /// No description provided for @aiChatDeleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get aiChatDeleteSessionTitle;

  /// No description provided for @aiChatDeleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}” and all messages in it? This cannot be undone.'**
  String aiChatDeleteSessionBody(String title);

  /// No description provided for @aiChatCompressedContextHeader.
  ///
  /// In en, this message translates to:
  /// **'Summary of the earlier conversation:'**
  String get aiChatCompressedContextHeader;

  /// No description provided for @llmProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get llmProviderTitle;

  /// No description provided for @llmProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure each vendor; switch without losing other profiles'**
  String get llmProviderSubtitle;

  /// No description provided for @llmApiKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get llmApiKeyTitle;

  /// No description provided for @llmApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your key'**
  String get llmApiKeyHint;

  /// No description provided for @llmBaseUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get llmBaseUrlTitle;

  /// No description provided for @llmBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://api.example.com/v1'**
  String get llmBaseUrlHint;

  /// No description provided for @llmTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get llmTestConnection;

  /// No description provided for @llmTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected — {count} models available'**
  String llmTestSuccess(int count);

  /// No description provided for @llmModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat model'**
  String get llmModelTitle;

  /// No description provided for @llmModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available after a successful test'**
  String get llmModelSubtitle;

  /// No description provided for @llmModelNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get llmModelNotSelected;

  /// No description provided for @aiChatNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set up your API key and run a connection test in Settings first.'**
  String get aiChatNotConfigured;

  /// No description provided for @aiChatThinkingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiChatThinkingInProgress;

  /// No description provided for @aiChatThinkingProcess.
  ///
  /// In en, this message translates to:
  /// **'Thinking process'**
  String get aiChatThinkingProcess;

  /// No description provided for @aiChatError.
  ///
  /// In en, this message translates to:
  /// **'Request failed: {error}'**
  String aiChatError(String error);

  /// No description provided for @aiChatDemoReply.
  ///
  /// In en, this message translates to:
  /// **'Received: {message}'**
  String aiChatDemoReply(String message);

  /// No description provided for @tooltipOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Open library'**
  String get tooltipOpenLibrary;

  /// No description provided for @librarySwitcherChooseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Choose another directory'**
  String get librarySwitcherChooseDirectory;

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

  /// No description provided for @mobileToolsDrawerReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag to reorder.'**
  String get mobileToolsDrawerReorderHint;

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

  /// No description provided for @booksSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get booksSheetTitle;

  /// No description provided for @booksSheetTagAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get booksSheetTagAll;

  /// No description provided for @newBookTitle.
  ///
  /// In en, this message translates to:
  /// **'New book'**
  String get newBookTitle;

  /// No description provided for @moreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick tools'**
  String get moreSheetTitle;

  /// No description provided for @mobileToolThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get mobileToolThemeMode;

  /// No description provided for @mobileToolSwitchTheme.
  ///
  /// In en, this message translates to:
  /// **'Switch theme'**
  String get mobileToolSwitchTheme;

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

  /// No description provided for @tooltipNewBook.
  ///
  /// In en, this message translates to:
  /// **'New book'**
  String get tooltipNewBook;

  /// No description provided for @tooltipBookGridLayout.
  ///
  /// In en, this message translates to:
  /// **'Two-column layout'**
  String get tooltipBookGridLayout;

  /// No description provided for @tooltipBookListLayout.
  ///
  /// In en, this message translates to:
  /// **'Single-column list'**
  String get tooltipBookListLayout;

  /// No description provided for @tooltipDeleteBook.
  ///
  /// In en, this message translates to:
  /// **'Delete book'**
  String get tooltipDeleteBook;

  /// No description provided for @deleteBookNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clear all chapters in this book before deleting it.'**
  String get deleteBookNotEmpty;

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

  /// No description provided for @quickToolbarSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get quickToolbarSearchTooltip;

  /// No description provided for @quickToolbarTimestampTooltip.
  ///
  /// In en, this message translates to:
  /// **'Insert timestamp'**
  String get quickToolbarTimestampTooltip;

  /// No description provided for @quickToolbarBackupTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get quickToolbarBackupTooltip;

  /// No description provided for @quickToolbarRestoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get quickToolbarRestoreTooltip;

  /// No description provided for @quickToolbarEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit toolbar'**
  String get quickToolbarEdit;

  /// No description provided for @quickToolbarEditHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press and drag on the toolbar to reorder. You can also drag here, or move tools between the fixed and custom zones.'**
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
  /// **'Nothing here yet'**
  String get quickToolbarDrawerEmpty;

  /// No description provided for @quickToolbarFormatApplyAll.
  ///
  /// In en, this message translates to:
  /// **'Format document'**
  String get quickToolbarFormatApplyAll;

  /// No description provided for @quickToolbarFormatKeepParagraphBlanks.
  ///
  /// In en, this message translates to:
  /// **'Keep blank lines between paragraphs'**
  String get quickToolbarFormatKeepParagraphBlanks;

  /// No description provided for @quickToolbarFormatRemoveParagraphBlanks.
  ///
  /// In en, this message translates to:
  /// **'Remove blank lines between paragraphs'**
  String get quickToolbarFormatRemoveParagraphBlanks;

  /// No description provided for @quickToolbarFormatInsertCjkLatinSpaces.
  ///
  /// In en, this message translates to:
  /// **'Space between Chinese and English'**
  String get quickToolbarFormatInsertCjkLatinSpaces;

  /// No description provided for @quickToolbarFormatAddParagraphIndent.
  ///
  /// In en, this message translates to:
  /// **'Indent paragraph starts'**
  String get quickToolbarFormatAddParagraphIndent;

  /// No description provided for @quickToolbarFormatRemoveParagraphIndent.
  ///
  /// In en, this message translates to:
  /// **'Remove paragraph indents'**
  String get quickToolbarFormatRemoveParagraphIndent;

  /// No description provided for @quickToolbarFormatSimplifiedToTraditional.
  ///
  /// In en, this message translates to:
  /// **'Simplified to Traditional Chinese'**
  String get quickToolbarFormatSimplifiedToTraditional;

  /// No description provided for @quickToolbarFormatTraditionalToSimplified.
  ///
  /// In en, this message translates to:
  /// **'Traditional to Simplified Chinese'**
  String get quickToolbarFormatTraditionalToSimplified;

  /// No description provided for @quickToolbarFormatHalfwidthToFullwidth.
  ///
  /// In en, this message translates to:
  /// **'Halfwidth to fullwidth symbols'**
  String get quickToolbarFormatHalfwidthToFullwidth;
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
