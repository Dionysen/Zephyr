/// Shell chrome typography, independent of the writing-column editor font.
class UiPreferences {
  const UiPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
  });

  /// [fontSize] maps to [TextTheme.titleSmall]; other styles scale from
  /// [referenceFontSize].
  static const defaults = UiPreferences(
    fontFamily: null,
    fontPath: null,
    fontSize: 13,
  );

  static const referenceFontSize = 15.0;

  final String? fontFamily;

  /// Durable system font identity used to re-register [fontFamily] on launch.
  final String? fontPath;
  final double fontSize;

  double get scale => fontSize / referenceFontSize;

  UiPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
  }) => UiPreferences(
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
  );
}
