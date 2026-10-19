import 'package:flutter/widgets.dart';

/// The visual language selected by the host product.
///
/// This is a product choice, independent of the operating system and window
/// width. Layout adaptations are handled separately by responsive widgets.
enum DesignStyle {
  material,
  cupertino,
  custom;

  static DesignStyle parse(String name) => switch (name) {
    'material' => DesignStyle.material,
    'cupertino' => DesignStyle.cupertino,
    'custom' => DesignStyle.custom,
    _ => throw ArgumentError.value(name, 'name', 'Unknown design style'),
  };
}

/// Makes the selected design language available to reusable widgets.
class DesignStyleScope extends InheritedWidget {
  const DesignStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  final DesignStyle style;

  static DesignStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesignStyleScope>()?.style ??
      DesignStyle.material;

  @override
  bool updateShouldNotify(DesignStyleScope oldWidget) =>
      style != oldWidget.style;
}
