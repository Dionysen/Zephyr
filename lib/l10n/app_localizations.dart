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
  /// **'Cloud sync'**
  String get settingsSectionCloud;

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
  /// **'Choose a theme, then customize its semantic tokens if needed.'**
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
  /// **'Theme presets'**
  String get themePresetsSectionTitle;

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
  /// **'Current theme: Custom'**
  String get themeCurrentCustomLong;

  /// No description provided for @themeCurrentPresetLong.
  ///
  /// In en, this message translates to:
  /// **'Current theme: {preset}'**
  String themeCurrentPresetLong(String preset);

  /// No description provided for @themePresetsFooter.
  ///
  /// In en, this message translates to:
  /// **'Theme presets apply to all writing-shell surfaces.'**
  String get themePresetsFooter;

  /// No description provided for @customColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom colors'**
  String get customColorsTitle;

  /// No description provided for @customColorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust semantic theme colors; changes apply immediately.'**
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

  /// No description provided for @restoreDarkModernDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore Dark Modern defaults'**
  String get restoreDarkModernDefaults;

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
  /// **'Jump to end'**
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
  /// **'Tap to choose light and dark theme packs.'**
  String get themePresetsSubtitle;
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
