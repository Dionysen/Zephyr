import 'package:flutter_primitives/design/design_style.dart';

/// The single product-level design choice. Override with
/// `--dart-define=ZEPHYR_DESIGN_STYLE=material|cupertino|custom`.
abstract final class ZephyrDesignConfig {
  static const String configuredStyle = String.fromEnvironment(
    'ZEPHYR_DESIGN_STYLE',
    defaultValue: 'custom',
  );

  static DesignStyle get style => DesignStyle.parse(configuredStyle);
}
