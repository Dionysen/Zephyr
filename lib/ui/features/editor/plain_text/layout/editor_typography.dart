import 'package:flutter/painting.dart';

/// Typography inputs for the plain-text layout engine.
class EditorTypography {
  const EditorTypography({
    required this.color,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.marginLeft,
    required this.marginRight,
    this.fontFamily,
    this.firstLineIndent = 0,
    this.paddingTop = 12,
    this.paddingBottom = 48,
  });

  final Color color;
  final double fontSize;
  final String? fontFamily;

  /// Multiplier applied inside a paragraph via [TextStyle.height].
  final double lineHeight;

  /// Gap after each paragraph (except the last), as a font-size multiplier.
  final double paragraphSpacing;

  /// Preferred left / right reading margins (px). Resolved against the
  /// viewport in [PlainTextLayoutEngine].
  final double marginLeft;
  final double marginRight;

  final int firstLineIndent;
  final double paddingTop;
  final double paddingBottom;

  double get paragraphGap => fontSize * paragraphSpacing;

  TextStyle get textStyle => TextStyle(
    color: color,
    fontSize: fontSize,
    height: lineHeight,
    fontFamily: fontFamily,
  );

  StrutStyle get strutStyle => StrutStyle(
    fontSize: fontSize,
    height: lineHeight,
    fontFamily: fontFamily,
    forceStrutHeight: true,
  );

  EditorTypography copyWith({
    Color? color,
    double? fontSize,
    String? fontFamily,
    bool clearFontFamily = false,
    double? lineHeight,
    double? paragraphSpacing,
    double? marginLeft,
    double? marginRight,
    int? firstLineIndent,
    double? paddingTop,
    double? paddingBottom,
  }) => EditorTypography(
    color: color ?? this.color,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    lineHeight: lineHeight ?? this.lineHeight,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    marginLeft: marginLeft ?? this.marginLeft,
    marginRight: marginRight ?? this.marginRight,
    firstLineIndent: firstLineIndent ?? this.firstLineIndent,
    paddingTop: paddingTop ?? this.paddingTop,
    paddingBottom: paddingBottom ?? this.paddingBottom,
  );

  @override
  bool operator ==(Object other) =>
      other is EditorTypography &&
      color == other.color &&
      fontSize == other.fontSize &&
      fontFamily == other.fontFamily &&
      lineHeight == other.lineHeight &&
      paragraphSpacing == other.paragraphSpacing &&
      marginLeft == other.marginLeft &&
      marginRight == other.marginRight &&
      firstLineIndent == other.firstLineIndent &&
      paddingTop == other.paddingTop &&
      paddingBottom == other.paddingBottom;

  @override
  int get hashCode => Object.hash(
    color,
    fontSize,
    fontFamily,
    lineHeight,
    paragraphSpacing,
    marginLeft,
    marginRight,
    firstLineIndent,
    paddingTop,
    paddingBottom,
  );
}
