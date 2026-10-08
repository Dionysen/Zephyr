/// Last known desktop window geometry, restored on the next launch.
class WindowFrame {
  const WindowFrame({
    required this.width,
    required this.height,
    this.x,
    this.y,
    this.maximized = false,
  });

  static const defaultWidth = 1280.0;
  static const defaultHeight = 800.0;
  static const defaults = WindowFrame(
    width: defaultWidth,
    height: defaultHeight,
  );

  final double width;
  final double height;
  final double? x;
  final double? y;
  final bool maximized;

  bool get hasPosition => x != null && y != null;

  WindowFrame copyWith({
    double? width,
    double? height,
    double? x,
    double? y,
    bool? maximized,
    bool clearPosition = false,
  }) => WindowFrame(
    width: width ?? this.width,
    height: height ?? this.height,
    x: clearPosition ? null : x ?? this.x,
    y: clearPosition ? null : y ?? this.y,
    maximized: maximized ?? this.maximized,
  );

  @override
  bool operator ==(Object other) =>
      other is WindowFrame &&
      width == other.width &&
      height == other.height &&
      x == other.x &&
      y == other.y &&
      maximized == other.maximized;

  @override
  int get hashCode => Object.hash(width, height, x, y, maximized);
}
