class EditorPreferences {
  const EditorPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    required this.maxContentWidth,
  });

  static const defaults = EditorPreferences(
    fontFamily: null,
    fontPath: null,
    fontSize: 18,
    lineHeight: 1.75,
    paragraphSpacing: 12,
    firstLineIndent: 2,
    maxContentWidth: 760,
  );

  final String? fontFamily;

  /// A durable system font identity. The font family is local to one Flutter
  /// engine after [SystemFontRepository.loadFont] registers it.
  final String? fontPath;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final int firstLineIndent;
  final double maxContentWidth;

  EditorPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    int? firstLineIndent,
    double? maxContentWidth,
  }) => EditorPreferences(
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    firstLineIndent: firstLineIndent ?? this.firstLineIndent,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
  );
}

class SystemFont {
  const SystemFont({required this.family, required this.path});
  final String family;
  final String path;
}
