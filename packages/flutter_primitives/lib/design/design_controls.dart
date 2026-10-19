import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design_style.dart';

/// A Boolean control selected by the product design style.
class DesignSwitch extends StatelessWidget {
  const DesignSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.materialScale = 1,
    this.materialTapTargetSize,
    this.alignment = Alignment.centerRight,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double materialScale;
  final MaterialTapTargetSize? materialTapTargetSize;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (DesignStyleScope.of(context) == DesignStyle.cupertino) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }
    final control = Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: materialTapTargetSize,
    );
    return materialScale == 1
        ? control
        : Transform.scale(
            scale: materialScale,
            alignment: alignment,
            child: control,
          );
  }
}

/// A numeric control selected by the product design style.
class DesignSlider extends StatelessWidget {
  const DesignSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.padding,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (DesignStyleScope.of(context) == DesignStyle.cupertino) {
      final control = CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
      );
      return padding == null
          ? control
          : Padding(padding: padding!, child: control);
    }
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      padding: padding,
    );
  }
}
