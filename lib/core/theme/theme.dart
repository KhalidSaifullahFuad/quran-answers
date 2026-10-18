import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'typography.dart';

/// Material theme built from the design tokens.
///
/// Material supplies ripples, focus and accessibility plumbing; everything the
/// reader sees is driven by [AppColors] and [AppText], which widgets read
/// directly. The design is flat — no elevation, no shadows, no dividers.
ThemeData buildTheme(
  Brightness brightness, {
  double arabicScale = 1.0,
  double bengaliScale = 1.0,
}) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.highlight,
        brightness: brightness,
      ).copyWith(
        surface: c.background,
        onSurface: c.fg1,
        onSurfaceVariant: c.fg3,
        primary: c.fg1,
        onPrimary: c.background,
        outline: c.fg4,
        outlineVariant: c.divider,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: Fonts.bengali,
    fontFamilyFallback: Fonts.latinFallback,
    scaffoldBackgroundColor: c.background,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    iconTheme: IconThemeData(color: c.fg1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.fg3),
    // The visible toast is drawn by showStatusToast; the bar itself is only a
    // transparent carrier, so it never reads as a full-width button.
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.fg2,
      inactiveTrackColor: c.track,
      thumbColor: c.fg1,
      overlayColor: c.fg1.withValues(alpha: .08),
      showValueIndicator: ShowValueIndicator.never,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.sheet,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.fg4,
    ),
    extensions: [
      c,
      AppText.from(c, arabicScale: arabicScale, bengaliScale: bengaliScale),
    ],
  );
}
