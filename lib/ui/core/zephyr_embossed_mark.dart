import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Flat gray Zephyr mark for empty surfaces.
class ZephyrEmbossedMark extends StatelessWidget {
  const ZephyrEmbossedMark({
    super.key,
    this.size = 240,
    this.opacity = 0.28,
  });

  final double size;

  /// How strongly the mark shows on the surface (lower = more transparent).
  final double opacity;

  static const _asset = 'branding/app_mark.svg';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = (dark ? Colors.white : Colors.black).withValues(
      alpha: opacity,
    );

    return ExcludeSemantics(
      child: SvgPicture.asset(
        _asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
