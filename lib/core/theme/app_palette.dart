import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// The app's semantic colours, resolved for the active brightness.
///
/// Why this exists: `AppColors` is a flat set of `static const` values, so a
/// widget writing `AppColors.textPrimary` gets the same near-black in both
/// themes. That is fine until a surface flips colour, and it is the reason
/// text has been disappearing -- the colour could not follow the surface it
/// was painted on.
///
/// Material's own `ColorScheme` covers primary/surface/error, but not the
/// tokens this app actually reasons in (success, warning, secondary text,
/// borders, chart series). A [ThemeExtension] is the supported way to add
/// those so they resolve per theme and animate with it, instead of being
/// looked up from a global.
///
/// Read it as `context.palette.textSecondary`. Brand hues (primary, success,
/// warning, error, accent, chart series) intentionally hold the same value in
/// both themes -- they are identity, not contrast. Only the neutrals flip.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Primary body text on [surface].
  final Color textPrimary;

  /// De-emphasised text: captions, helper text, list subtitles.
  final Color textSecondary;

  /// Text for disabled controls and placeholder/hint text.
  final Color textDisabled;

  /// Text painted on a filled brand colour (buttons, gradient headers).
  /// Named for its role rather than "white", because on a light brand fill it
  /// is not white.
  final Color textOnBrand;

  /// The page background.
  final Color background;

  /// Raised content: cards, sheets, menus, input fills.
  final Color surface;

  /// A surface one step further from the background, for nested content.
  final Color surfaceVariant;

  /// Hairlines and control outlines.
  final Color border;
  final Color divider;

  // Brand and status. Same in both themes.
  final Color primary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accent;

  const AppPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.textOnBrand,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.divider,
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accent,
  });

  static const AppPalette light = AppPalette(
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    textOnBrand: AppColors.textWhite,
    background: AppColors.background,
    surface: AppColors.background,
    surfaceVariant: AppColors.surface,
    border: AppColors.border,
    divider: AppColors.divider,
    primary: AppColors.primary,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    accent: AppColors.accent,
  );

  /// Dark mode neutrals. Content surfaces are genuinely dark here: the old
  /// theme kept white cards on a dark scaffold, which left no single text
  /// colour that worked on both and is what made text vanish.
  static const AppPalette dark = AppPalette(
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textDisabled: AppColors.textDisabled,
    // Dark mode lightens the brand blue so it reads against a dark page, and
    // white on that lighter fill only reaches 2.5:1. Dark text on it clears
    // 5.5:1, and it matches the ColorScheme's onPrimary for the same reason.
    textOnBrand: AppColors.backgroundDark,
    background: AppColors.surfaceDarkRaised,
    surface: AppColors.backgroundDark,
    surfaceVariant: AppColors.surfaceDark,
    border: AppColors.borderDark,
    divider: AppColors.borderDark,
    primary: AppColors.primaryLight,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    accent: AppColors.accent,
  );

  @override
  AppPalette copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? textOnBrand,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? border,
    Color? divider,
    Color? primary,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? accent,
  }) {
    return AppPalette(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppPalette(
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textDisabled: mix(textDisabled, other.textDisabled),
      textOnBrand: mix(textOnBrand, other.textOnBrand),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceVariant: mix(surfaceVariant, other.surfaceVariant),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      primary: mix(primary, other.primary),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      info: mix(info, other.info),
      accent: mix(accent, other.accent),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette for the active theme.
  ///
  /// Falls back to the light palette rather than throwing when the extension
  /// is missing, so a widget rendered outside the app's theme (a bare
  /// `MaterialApp` in a widget test, for instance) still paints something
  /// legible instead of crashing.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
