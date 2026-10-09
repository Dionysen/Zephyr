class EditorPreferences {
  const EditorPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    required this.maxContentWidth,
    required this.titleFontSize,
    required this.titleCentered,
  });

  static const defaults = EditorPreferences(
    fontFamily: null,
    fontPath: null,
    fontSize: 15,
    lineHeight: 1.75,
    paragraphSpacing: 0.5,
    firstLineIndent: 2,
    maxContentWidth: 760,
    titleFontSize: 25,
    titleCentered: true,
  );

  static const minTitleFontSize = 14.0;
  static const maxTitleFontSize = 48.0;

  final String? fontFamily;

  /// A durable system font identity. The font family is local to one Flutter
  /// engine after [SystemFontRepository.loadFont] registers it.
  final String? fontPath;
  final double fontSize;

  /// Line-height multiplier for wrapping lines inside a paragraph.
  final double lineHeight;

  /// Gap between paragraphs as a font-size multiplier (block padding).
  final double paragraphSpacing;
  final int firstLineIndent;
  final double maxContentWidth;

  /// Chapter title block above the writing column.
  final double titleFontSize;

  /// When true, title text is centered in the reading column; otherwise
  /// left-aligned to the same edge as the body.
  final bool titleCentered;

  EditorPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    int? firstLineIndent,
    double? maxContentWidth,
    double? titleFontSize,
    bool? titleCentered,
  }) => EditorPreferences(
    fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    firstLineIndent: firstLineIndent ?? this.firstLineIndent,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    titleFontSize: titleFontSize ?? this.titleFontSize,
    titleCentered: titleCentered ?? this.titleCentered,
  );
}

class SystemFont {
  const SystemFont({
    required this.family,
    required this.path,
    this.imported = false,
  });
  final String family;
  final String path;

  /// True when the file lives in the app-owned fonts directory (can be deleted).
  final bool imported;

  @override
  bool operator ==(Object other) => other is SystemFont && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
