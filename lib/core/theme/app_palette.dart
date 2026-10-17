import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Returns the black or white foreground with the stronger contrast against
/// a solid fill. Useful when a status or brand colour changes with the theme.
Color foregroundFor(Color background) =>
    background.computeLuminance() > 0.179 ? Colors.black : Colors.white;

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
/// Read it as `context.palette.textSecondary`. Neutrals flip between themes;
/// `primary` is deep navy in light mode and metallic gold in dark mode, and the
/// status hues are brightened in dark mode for contrast on obsidian surfaces.
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

  /// De-emphasised text painted on a filled brand colour.
  Color get textOnBrand70 => textOnBrand.withValues(alpha: 0.7);

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
    surface: AppColors.surfaceLight,
    surfaceVariant: AppColors.secondary,
    border: AppColors.border,
    divider: AppColors.divider,
    primary: AppColors.primary,
    // Status and accent hues are darkened here so they pass 4.5:1 as text on
    // the porcelain surface and on their own 15% tinted badge. The brand
    // constants are too pale on white (gold 2.1:1, amber 3.6:1, green 3.3:1,
    // red 3.5:1 on its tint).
    success: Color(0xFF166534),
    warning: Color(0xFF92400E),
    error: Color(0xFFB91C1C),
    info: Color(0xFF075985),
    accent: Color(0xFF7C5C12),
  );

  /// Dark mode neutrals. Content surfaces are genuinely dark here: the old
  /// theme kept white cards on a dark scaffold, which left no single text
  /// colour that worked on both and is what made text vanish.
  static const AppPalette dark = AppPalette(
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textDisabled: AppColors.textDisabledDark,
    // Dark mode primary actions are metallic gold; obsidian navy text on that
    // fill preserves strong contrast.
    textOnBrand: AppColors.backgroundDark,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceVariant: AppColors.surfaceDarkRaised,
    border: AppColors.borderDark,
    divider: AppColors.borderDark,
    primary: AppColors.gold,
    success: Color(0xFF4ADE80),
    warning: AppColors.goldLight,
    error: Color(0xFFFF8A80),
    info: AppColors.cyan,
    accent: AppColors.gold,
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
