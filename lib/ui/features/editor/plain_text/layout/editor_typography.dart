import 'package:flutter/painting.dart';

/// Typography inputs for the plain-text layout engine.
class EditorTypography {
  const EditorTypography({
    required this.color,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.maxContentWidth,
    this.fontFamily,
    this.firstLineIndent = 0,
    this.documentPadding = const EdgeInsets.fromLTRB(42, 28, 42, 48),
  });

  final Color color;
  final double fontSize;
  final String? fontFamily;

  /// Multiplier applied inside a paragraph via [TextStyle.height].
  final double lineHeight;

  /// Gap after each paragraph (except the last), as a font-size multiplier.
  final double paragraphSpacing;

  final double maxContentWidth;
  final int firstLineIndent;
  final EdgeInsets documentPadding;

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
    double? maxContentWidth,
    int? firstLineIndent,
    EdgeInsets? documentPadding,
  }) => EditorTypography(
    color: color ?? this.color,
    fontSize: fontSize ?? this.fontSize,
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    lineHeight: lineHeight ?? this.lineHeight,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    firstLineIndent: firstLineIndent ?? this.firstLineIndent,
    documentPadding: documentPadding ?? this.documentPadding,
  );

  @override
  bool operator ==(Object other) =>
      other is EditorTypography &&
      color == other.color &&
      fontSize == other.fontSize &&
      fontFamily == other.fontFamily &&
      lineHeight == other.lineHeight &&
      paragraphSpacing == other.paragraphSpacing &&
      maxContentWidth == other.maxContentWidth &&
      firstLineIndent == other.firstLineIndent &&
      documentPadding == other.documentPadding;

  @override
  int get hashCode => Object.hash(
    color,
    fontSize,
    fontFamily,
    lineHeight,
    paragraphSpacing,
    maxContentWidth,
    firstLineIndent,
    documentPadding,
  );
}
