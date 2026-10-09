/// Shell chrome typography and shape, independent of the writing-column editor.
class UiPreferences {
  const UiPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
    required this.cornerRadius,
    required this.showBorders,
    required this.sidebarItemInset,
  });

  /// [fontSize] maps to [TextTheme.titleSmall]; other styles scale from
  /// [referenceFontSize].
  static const defaults = UiPreferences(
    fontFamily: null,
    fontPath: null,
    fontSize: 16,
    cornerRadius: 8,
    showBorders: true,
    sidebarItemInset: 6,
  );

  static const referenceFontSize = 15.0;
  static const minCornerRadius = 0.0;
  static const maxCornerRadius = 20.0;
  static const minSidebarItemInset = 0.0;
  static const maxSidebarItemInset = 24.0;

  final String? fontFamily;

  /// Durable system font identity used to re-register [fontFamily] on launch.
  final String? fontPath;
  final double fontSize;

  /// Shared corner radius for chrome controls, menus, cards, and dialogs.
  final double cornerRadius;

  /// When false, chrome controls omit outline borders; volume rows and the
  /// library dock also drop their strokes.
  final bool showBorders;

  /// Equal left/right inset for sidebar volume and chapter rows.
  final double sidebarItemInset;

  double get scale => fontSize / referenceFontSize;

  UiPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
    double? cornerRadius,
    bool? showBorders,
    double? sidebarItemInset,
  }) => UiPreferences(
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    showBorders: showBorders ?? this.showBorders,
    sidebarItemInset: sidebarItemInset ?? this.sidebarItemInset,
  );
}
