/// Shell chrome typography and shape, independent of the writing-column editor.
class UiPreferences {
  const UiPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
    required this.cornerRadius,
  });

  /// [fontSize] maps to [TextTheme.titleSmall]; other styles scale from
  /// [referenceFontSize].
  static const defaults = UiPreferences(
    fontFamily: null,
    fontPath: null,
    fontSize: 16,
    cornerRadius: 8,
  );

  static const referenceFontSize = 15.0;
  static const minCornerRadius = 0.0;
  static const maxCornerRadius = 20.0;

  final String? fontFamily;

  /// Durable system font identity used to re-register [fontFamily] on launch.
  final String? fontPath;
  final double fontSize;

  /// Shared corner radius for chrome controls, menus, cards, and dialogs.
  final double cornerRadius;

  double get scale => fontSize / referenceFontSize;

  UiPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
    double? cornerRadius,
  }) => UiPreferences(
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
    cornerRadius: cornerRadius ?? this.cornerRadius,
  );
}
