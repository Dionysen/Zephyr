import 'editor_background.dart';
import 'zephyr_bundled_fonts.dart';

/// Interface language preference stored with other UI chrome settings.
enum AppLocalePreference {
  system,
  chinese,
  english;

  String get storageValue => switch (this) {
    AppLocalePreference.system => 'system',
    AppLocalePreference.chinese => 'zh',
    AppLocalePreference.english => 'en',
  };

  static AppLocalePreference fromStorage(String? value) => switch (value) {
    'zh' || 'zh_CN' || 'zh-CN' || 'chinese' => AppLocalePreference.chinese,
    'en' || 'en_US' || 'en-US' || 'english' => AppLocalePreference.english,
    _ => AppLocalePreference.system,
  };
}

/// Shell chrome typography and shape, independent of the writing-column editor.
class UiPreferences {
  const UiPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
    required this.cornerRadius,
    required this.barCornerRadius,
    required this.showBorders,
    required this.sidebarItemInset,
    required this.sidebarVolumeGap,
    required this.immersiveStatusBar,
    required this.hideStatusBarIcons,
    required this.hideQuickToolbar,
    required this.showChapterDetails,
    required this.editorBackgroundEnabled,
    required this.localePreference,
    this.mobileToolsOrder = const [],
    this.cloudBackupMenuOrder = const [],
    this.lightEditorBackground = EditorBackgroundConfig.defaults,
    this.darkEditorBackground = EditorBackgroundConfig.defaults,
  });

  /// [fontSize] maps to [TextTheme.titleSmall]; other styles scale from
  /// [referenceFontSize].
  static const defaults = UiPreferences(
    fontFamily: ZephyrBundledFonts.wenkaiLite,
    fontPath: null,
    fontSize: 16,
    cornerRadius: 4,
    barCornerRadius: 4,
    showBorders: false,
    sidebarItemInset: 0,
    sidebarVolumeGap: 1,
    immersiveStatusBar: true,
    hideStatusBarIcons: true,
    hideQuickToolbar: false,
    showChapterDetails: true,
    editorBackgroundEnabled: true,
    localePreference: AppLocalePreference.system,
    mobileToolsOrder: [],
    cloudBackupMenuOrder: [],
  );

  static const referenceFontSize = 15.0;
  static const minCornerRadius = 0.0;
  static const maxCornerRadius = 20.0;
  static const minBarCornerRadius = 0.0;
  static const maxBarCornerRadius = 24.0;
  static const minSidebarItemInset = 0.0;
  static const maxSidebarItemInset = 24.0;
  static const minSidebarVolumeGap = 1.0;
  static const maxSidebarVolumeGap = 10.0;

  final String? fontFamily;

  /// Durable system font identity used to re-register [fontFamily] on launch.
  final String? fontPath;
  final double fontSize;

  /// Shared corner radius for chrome controls, menus, cards, and dialogs.
  final double cornerRadius;

  /// Corner radius for the floating editor top bar and the sidebar library dock.
  final double barCornerRadius;

  /// When false, chrome controls omit outline borders; volume rows and the
  /// library dock also drop their strokes.
  final bool showBorders;

  /// Equal left/right inset for sidebar volume and chapter rows.
  final double sidebarItemInset;

  /// Vertical gap between volume groups in the sidebar.
  final double sidebarVolumeGap;

  /// When true, the shell draws under a transparent status band (chrome
  /// reserved) and reading content may scroll into that band.
  final bool immersiveStatusBar;

  /// When [immersiveStatusBar] is true, hides system status icons
  /// (immersive sticky). Ignored while immersive is off.
  final bool hideStatusBarIcons;

  /// When true, the IME quick input toolbar above the soft keyboard is hidden.
  final bool hideQuickToolbar;

  /// When true, sidebar chapter rows show preview text and meta (dates / words).
  /// When false, only the chapter title is shown.
  final bool showChapterDetails;

  /// Master switch for writing-column background images. When false, stored
  /// light/dark configs are kept but not painted.
  final bool editorBackgroundEnabled;

  /// App UI language: system, Simplified Chinese, or English.
  final AppLocalePreference localePreference;

  /// Stable ids for the compact editor “more” tools sheet order.
  ///
  /// Empty means use the order tools were registered in.
  final List<String> mobileToolsOrder;

  /// Stable ids for the mobile cloud-backup drawer actions.
  ///
  /// Empty means use the registration order (backup / restore / auto).
  final List<String> cloudBackupMenuOrder;

  /// Writing-column background image for light appearance.
  final EditorBackgroundConfig lightEditorBackground;

  /// Writing-column background image for dark appearance.
  final EditorBackgroundConfig darkEditorBackground;

  double get scale => fontSize / referenceFontSize;

  /// Stored config for [dark] (ignores [editorBackgroundEnabled]).
  EditorBackgroundConfig editorBackgroundFor({required bool dark}) =>
      dark ? darkEditorBackground : lightEditorBackground;

  /// Config the workspace should paint — empty when the master switch is off.
  EditorBackgroundConfig activeEditorBackgroundFor({required bool dark}) {
    if (!editorBackgroundEnabled) {
      return EditorBackgroundConfig.defaults;
    }
    return editorBackgroundFor(dark: dark);
  }

  UiPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
    double? cornerRadius,
    double? barCornerRadius,
    bool? showBorders,
    double? sidebarItemInset,
    double? sidebarVolumeGap,
    bool? immersiveStatusBar,
    bool? hideStatusBarIcons,
    bool? hideQuickToolbar,
    bool? showChapterDetails,
    bool? editorBackgroundEnabled,
    AppLocalePreference? localePreference,
    List<String>? mobileToolsOrder,
    List<String>? cloudBackupMenuOrder,
    EditorBackgroundConfig? lightEditorBackground,
    EditorBackgroundConfig? darkEditorBackground,
  }) => UiPreferences(
    fontFamily: clearFontFamily
        ? ZephyrBundledFonts.wenkaiLite
        : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    showBorders: showBorders ?? this.showBorders,
    sidebarItemInset: sidebarItemInset ?? this.sidebarItemInset,
    sidebarVolumeGap: sidebarVolumeGap ?? this.sidebarVolumeGap,
    immersiveStatusBar: immersiveStatusBar ?? this.immersiveStatusBar,
    hideStatusBarIcons: hideStatusBarIcons ?? this.hideStatusBarIcons,
    hideQuickToolbar: hideQuickToolbar ?? this.hideQuickToolbar,
    showChapterDetails: showChapterDetails ?? this.showChapterDetails,
    editorBackgroundEnabled:
        editorBackgroundEnabled ?? this.editorBackgroundEnabled,
    localePreference: localePreference ?? this.localePreference,
    mobileToolsOrder: mobileToolsOrder ?? this.mobileToolsOrder,
    cloudBackupMenuOrder: cloudBackupMenuOrder ?? this.cloudBackupMenuOrder,
    lightEditorBackground:
        lightEditorBackground ?? this.lightEditorBackground,
    darkEditorBackground: darkEditorBackground ?? this.darkEditorBackground,
  );
}
