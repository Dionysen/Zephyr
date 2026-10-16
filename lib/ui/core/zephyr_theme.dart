import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../domain/models/theme_tokens.dart';
import '../../domain/models/ui_preferences.dart';
import 'zephyr_controls.dart';
import 'zephyr_status_bar.dart';

/// User-owned chrome shape prefs exposed through [ThemeData.extensions].
@immutable
class ZephyrShapeTheme extends ThemeExtension<ZephyrShapeTheme> {
  const ZephyrShapeTheme({
    required this.cornerRadius,
    this.barCornerRadius = 4,
    this.showBorders = false,
    this.sidebarItemInset = 0,
    this.sidebarItemCornerRadius = 4,
    this.sidebarVolumeGap = 1,
  });

  final double cornerRadius;
  final double barCornerRadius;
  final bool showBorders;
  final double sidebarItemInset;
  final double sidebarItemCornerRadius;
  final double sidebarVolumeGap;

  BorderRadius get borderRadius => BorderRadius.circular(cornerRadius);

  BorderRadius get sidebarItemBorderRadius =>
      BorderRadius.circular(sidebarItemCornerRadius);

  BorderRadius get barBorderRadius => BorderRadius.circular(barCornerRadius);

  OutlinedBorder get iconButtonShape =>
      ZephyrControls.iconButtonShapeFor(cornerRadius);

  OutlinedBorder get labeledButtonShape =>
      ZephyrControls.labeledButtonShapeFor(cornerRadius);

  OutlinedBorder get menuShape => ZephyrControls.menuShapeFor(cornerRadius);

  BorderSide outlineSide(Color color) => showBorders
      ? BorderSide(color: color, width: ZephyrControls.borderWidth)
      : BorderSide.none;

  @override
  ZephyrShapeTheme copyWith({
    double? cornerRadius,
    double? barCornerRadius,
    bool? showBorders,
    double? sidebarItemInset,
    double? sidebarItemCornerRadius,
    double? sidebarVolumeGap,
  }) => ZephyrShapeTheme(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    barCornerRadius: barCornerRadius ?? this.barCornerRadius,
    showBorders: showBorders ?? this.showBorders,
    sidebarItemInset: sidebarItemInset ?? this.sidebarItemInset,
    sidebarItemCornerRadius:
        sidebarItemCornerRadius ?? this.sidebarItemCornerRadius,
    sidebarVolumeGap: sidebarVolumeGap ?? this.sidebarVolumeGap,
  );

  @override
  ZephyrShapeTheme lerp(ThemeExtension<ZephyrShapeTheme>? other, double t) {
    if (other is! ZephyrShapeTheme) return this;
    return ZephyrShapeTheme(
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t)!,
      barCornerRadius: lerpDouble(barCornerRadius, other.barCornerRadius, t)!,
      showBorders: t < 0.5 ? showBorders : other.showBorders,
      sidebarItemInset: lerpDouble(
        sidebarItemInset,
        other.sidebarItemInset,
        t,
      )!,
      sidebarItemCornerRadius: lerpDouble(
        sidebarItemCornerRadius,
        other.sidebarItemCornerRadius,
        t,
      )!,
      sidebarVolumeGap: lerpDouble(
        sidebarVolumeGap,
        other.sidebarVolumeGap,
        t,
      )!,
    );
  }
}

extension ZephyrThemeContext on BuildContext {
  ZephyrShapeTheme get zephyrShape =>
      Theme.of(this).extension<ZephyrShapeTheme>() ??
      const ZephyrShapeTheme(cornerRadius: ZephyrControls.defaultCornerRadius);

  double get zephyrCornerRadius => zephyrShape.cornerRadius;

  BorderRadius get zephyrBorderRadius => zephyrShape.borderRadius;

  double get zephyrBarCornerRadius => zephyrShape.barCornerRadius;

  BorderRadius get zephyrBarBorderRadius => zephyrShape.barBorderRadius;

  bool get zephyrShowBorders => zephyrShape.showBorders;

  double get zephyrSidebarItemInset => zephyrShape.sidebarItemInset;

  BorderRadius get zephyrSidebarItemBorderRadius =>
      zephyrShape.sidebarItemBorderRadius;

  double get zephyrSidebarVolumeGap => zephyrShape.sidebarVolumeGap;

  BorderSide zephyrOutlineSide([Color? color]) =>
      zephyrShape.outlineSide(color ?? Theme.of(this).colorScheme.outline);
}

/// Builds the writing-shell theme from user-owned semantic tokens.
ThemeData zephyrTheme(
  ThemeTokens tokens, {
  UiPreferences ui = UiPreferences.defaults,
}) {
  final editor = Color(tokens.editorSurface);
  final sidebar = Color(tokens.sidebarSurface);
  final control = Color(tokens.controlSurface);
  final border = Color(tokens.border);
  final divider = Color(tokens.divider);
  final primaryText = Color(tokens.primaryText);
  final mutedText = Color(tokens.mutedText);
  final accent = Color(tokens.accent);
  final cursor = Color(tokens.cursor);
  final brightness = editor.computeLuminance() < .5
      ? Brightness.dark
      : Brightness.light;
  final selected = Color.alphaBlend(accent.withValues(alpha: .20), sidebar);
  final focus = Color.alphaBlend(accent.withValues(alpha: .5), border);
  final scale = ui.scale;
  final fontFamily = ui.fontFamily;
  final radius = ui.cornerRadius.clamp(
    UiPreferences.minCornerRadius,
    UiPreferences.maxCornerRadius,
  );
  final barRadius = ui.barCornerRadius.clamp(
    UiPreferences.minBarCornerRadius,
    UiPreferences.maxBarCornerRadius,
  );
  final itemInset = ui.sidebarItemInset.clamp(
    UiPreferences.minSidebarItemInset,
    UiPreferences.maxSidebarItemInset,
  );
  final sidebarItemRadius = ui.sidebarItemCornerRadius.clamp(
    UiPreferences.minCornerRadius,
    UiPreferences.maxCornerRadius,
  );
  final volumeGap = ui.sidebarVolumeGap.clamp(
    UiPreferences.minSidebarVolumeGap,
    UiPreferences.maxSidebarVolumeGap,
  );
  final shape = ZephyrShapeTheme(
    cornerRadius: radius,
    barCornerRadius: barRadius,
    showBorders: ui.showBorders,
    sidebarItemInset: itemInset,
    sidebarItemCornerRadius: sidebarItemRadius,
    sidebarVolumeGap: volumeGap,
  );
  final borderRadius = shape.borderRadius;
  final hairline = shape.outlineSide(border);
  final focusHairline = shape.outlineSide(focus);

  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    extensions: [shape],
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
        .copyWith(
          primary: accent,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.white,
          secondaryContainer: selected,
          onSecondaryContainer: primaryText,
          // Keep tonal containers from the seed from darkening switches / chips.
          primaryContainer: Color.alphaBlend(
            accent.withValues(alpha: brightness == Brightness.dark ? .28 : .18),
            editor,
          ),
          onPrimaryContainer: primaryText,
          surface: editor,
          onSurface: primaryText,
          surfaceContainerLowest: sidebar,
          surfaceContainerLow: Color.alphaBlend(
            Colors.white.withValues(alpha: .02),
            sidebar,
          ),
          surfaceContainer: Color.alphaBlend(
            Colors.white.withValues(alpha: .03),
            editor,
          ),
          surfaceContainerHigh: control,
          surfaceContainerHighest: Color.alphaBlend(
            Colors.white.withValues(alpha: .04),
            control,
          ),
          onSurfaceVariant: mutedText,
          outline: border,
          outlineVariant: divider,
          error: brightness == Brightness.light
              ? const Color(0xFFB3261E)
              : const Color(0xFFFFB4AB),
          onError: brightness == Brightness.light ? Colors.white : null,
        ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent;
        }
        return null;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return null;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: .12);
        }
        return mutedText.withValues(alpha: .08);
      }),
    ),
    scaffoldBackgroundColor: editor,
    dividerTheme: DividerThemeData(
      color: divider,
      thickness: ZephyrControls.borderWidth,
      space: 1,
    ),
    iconTheme: IconThemeData(
      color: primaryText.withValues(alpha: .76),
      size: ZephyrControls.iconSize,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: primaryText.withValues(alpha: .76),
        iconSize: ZephyrControls.iconSize,
        padding: EdgeInsets.zero,
        minimumSize: const Size(
          ZephyrControls.buttonSize,
          ZephyrControls.buttonSize,
        ),
        fixedSize: const Size(
          ZephyrControls.buttonSize,
          ZephyrControls.buttonSize,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: shape.iconButtonShape,
        overlayColor: accent.withValues(alpha: .12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryText,
        iconSize: ZephyrControls.iconSize,
        shape: shape.labeledButtonShape.copyWith(side: hairline),
        side: hairline,
        visualDensity: VisualDensity.compact,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryText,
        iconSize: ZephyrControls.iconSize,
        shape: shape.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: primaryText,
        backgroundColor: accent.withValues(alpha: .24),
        iconSize: ZephyrControls.iconSize,
        shape: shape.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: primaryText,
        fontFamily: fontFamily,
        fontSize: 20 * scale,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: primaryText,
        fontFamily: fontFamily,
        fontSize: 15 * scale,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: TextStyle(
        color: primaryText,
        fontFamily: fontFamily,
        fontSize: 16 * scale,
        height: 1.75,
      ),
      bodySmall: TextStyle(
        color: mutedText,
        fontFamily: fontFamily,
        fontSize: 13 * scale,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        color: primaryText.withValues(alpha: .70),
        fontFamily: fontFamily,
        fontSize: 12 * scale,
      ),
      labelSmall: TextStyle(
        color: mutedText.withValues(alpha: .82),
        fontFamily: fontFamily,
        fontSize: 11 * scale,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: editor,
      foregroundColor: primaryText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: ZephyrStatusBar.styleFor(
        brightness,
        immersive: ui.immersiveStatusBar,
        hideIcons: ui.hideStatusBarIcons,
        statusBarColor: editor,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cursor,
      selectionColor: accent.withValues(alpha: .35),
      selectionHandleColor: cursor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: control,
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderSide: hairline,
        borderRadius: borderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: focusHairline,
        borderRadius: borderRadius,
      ),
      hintStyle: TextStyle(color: mutedText.withValues(alpha: .78)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: control,
      shape: RoundedRectangleBorder(borderRadius: borderRadius, side: hairline),
    ),
    cardTheme: CardThemeData(
      color: control,
      shape: RoundedRectangleBorder(borderRadius: borderRadius, side: hairline),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: control, borderRadius: borderRadius),
      textStyle: TextStyle(color: primaryText),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(control),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: .32),
        ),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: ZephyrControls.menuInsets),
        ),
        shape: WidgetStatePropertyAll(shape.menuShape.copyWith(side: hairline)),
        visualDensity: VisualDensity.compact,
      ),
    ),
    // Match [ZephyrDropdown] rows ([fieldHeight]). Avoid compact density —
    // it shrinks below the declared size and no longer matches the book picker.
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(64, ZephyrControls.menuItemHeight),
        ),
        fixedSize: const WidgetStatePropertyAll(
          Size.fromHeight(ZephyrControls.menuItemHeight),
        ),
        maximumSize: const WidgetStatePropertyAll(
          Size(double.infinity, ZephyrControls.menuItemHeight),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        iconSize: const WidgetStatePropertyAll(ZephyrControls.iconSize),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: control,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: shape.menuShape.copyWith(side: hairline),
      menuPadding: const EdgeInsets.symmetric(
        vertical: ZephyrControls.menuInsets,
      ),
    ),
    splashFactory: InkRipple.splashFactory,
    splashColor: accent.withValues(alpha: .14),
    highlightColor: accent.withValues(alpha: .08),
  );
}

/// Circular icon buttons; labeled buttons use the settings corner radius.
ThemeData withMobileRoundControls(ThemeData theme) {
  const circle = CircleBorder();
  final shape = theme.extension<ZephyrShapeTheme>();
  final labeled =
      shape?.labeledButtonShape ?? ZephyrControls.labeledButtonShape;
  final onSurface = theme.colorScheme.onSurface;
  final accent = theme.colorScheme.primary;
  final outline = theme.colorScheme.outline;
  final hairline =
      shape?.outlineSide(outline) ??
      BorderSide(color: outline, width: ZephyrControls.borderWidth);

  return theme.copyWith(
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: onSurface.withValues(alpha: .76),
        iconSize: ZephyrControls.mobileIconSize,
        padding: EdgeInsets.zero,
        minimumSize: const Size(
          ZephyrControls.mobileButtonSize,
          ZephyrControls.mobileButtonSize,
        ),
        fixedSize: const Size(
          ZephyrControls.mobileButtonSize,
          ZephyrControls.mobileButtonSize,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: circle,
        overlayColor: accent.withValues(alpha: .12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: onSurface,
        iconSize: ZephyrControls.mobileIconSize,
        shape: labeled,
        visualDensity: VisualDensity.compact,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: onSurface,
        backgroundColor: accent.withValues(alpha: .24),
        iconSize: ZephyrControls.mobileIconSize,
        shape: labeled,
        visualDensity: VisualDensity.compact,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        iconSize: ZephyrControls.mobileIconSize,
        shape: labeled.copyWith(side: hairline),
        side: hairline,
        visualDensity: VisualDensity.compact,
      ),
    ),
  );
}
