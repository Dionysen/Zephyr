import 'package:flutter/material.dart';

import '../../domain/models/ui_preferences.dart';

/// Chat bubble corners: sharp top-outer corner, continuous curve elsewhere.
BorderRadius zephyrChatBubbleBorderRadius({
  required bool isUser,
  required double radius,
}) {
  final r = radius.clamp(0.0, UiPreferences.maxChatBubbleCornerRadius);
  return BorderRadius.only(
    topLeft: Radius.circular(isUser ? r : 0),
    topRight: Radius.circular(isUser ? 0 : r),
    bottomLeft: Radius.circular(r),
    bottomRight: Radius.circular(r),
  );
}

ShapeDecoration zephyrChatBubbleDecoration({
  required Color color,
  required bool isUser,
  required double radius,
}) {
  return ShapeDecoration(
    color: color,
    shape: ContinuousRectangleBorder(
      borderRadius: zephyrChatBubbleBorderRadius(
        isUser: isUser,
        radius: radius,
      ),
    ),
  );
}

/// Continuous-curve pill / rounded rect (e.g. AI chat composer chrome).
ShapeDecoration zephyrContinuousRoundedDecoration({
  required Color color,
  required double radius,
  List<BoxShadow>? shadows,
}) {
  final r = radius.clamp(0.0, 80.0);
  return ShapeDecoration(
    color: color,
    shadows: shadows,
    shape: ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(r),
    ),
  );
}
