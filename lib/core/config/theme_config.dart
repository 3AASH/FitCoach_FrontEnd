import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../theme/app_palette.dart';

/// Theme configuration that matches the React design system
/// (globals.css and the shadcn/ui components).
///
/// Both themes are produced by the same [_build] function from an
/// [AppPalette]. They used to be related by `light.copyWith(...)`, which was
/// the source of most of the unreadable text in the app: `copyWith` replaces
/// only the sub-themes named in the call, so every light sub-theme that was
/// not re-listed -- chips, sliders, tooltips, menus, expansion tiles, tabs --
/// stayed light on a dark scaffold. Building each theme from its own palette
/// means a new sub-theme is correct in both themes the moment it is added
/// here, instead of being correct in light and forgotten in dark.
class AppThemeConfig {
  static ThemeData getLightTheme() =>
      _build(AppPalette.light, Brightness.light);

  static ThemeData getDarkTheme() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.textOnBrand,
      secondary: isDark ? AppColors.cyan : AppColors.gold,
      onSecondary: isDark ? AppColors.backgroundDark : AppColors.textPrimary,
      error: p.error,
      onError: isDark ? AppColors.backgroundDark : Colors.white,
      // `surface` is the colour Material paints cards, sheets, menus and
      // dialogs with, and `onSurface` the text on top of them. The dark theme
      // previously set surface to white while keeping onSurface near-black,
      // which is why raised content in dark mode looked like a light-theme
      // island and any text the app coloured itself went invisible.
      surface: p.surface,
      onSurface: p.textPrimary,
      surfaceContainerHighest: p.surfaceVariant,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.divider,
    );

    // Typography carries explicit colours. A TextStyle with a null colour
    // inherits from whatever DefaultTextStyle is in scope, which inside an
    // overlay (menu, bottom sheet, autocomplete popup) is not the page's text
    // colour -- that is how white-on-white rows happened.
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.h1.copyWith(color: p.textPrimary),
      displayMedium: AppTextStyles.h2.copyWith(color: p.textPrimary),
      displaySmall: AppTextStyles.h3.copyWith(color: p.textPrimary),
      headlineMedium: AppTextStyles.h3.copyWith(color: p.textPrimary),
      headlineSmall: AppTextStyles.h4.copyWith(color: p.textPrimary),
      titleLarge: AppTextStyles.h3.copyWith(color: p.textPrimary),
      titleMedium: AppTextStyles.h4.copyWith(color: p.textPrimary),
      titleSmall: AppTextStyles.bodyMedium.copyWith(color: p.textPrimary),
      bodyLarge: AppTextStyles.body.copyWith(color: p.textPrimary),
      bodyMedium: AppTextStyles.body.copyWith(color: p.textPrimary),
      bodySmall: AppTextStyles.small.copyWith(color: p.textSecondary),
      labelLarge: AppTextStyles.label.copyWith(color: p.textPrimary),
      labelMedium: AppTextStyles.captionMedium.copyWith(color: p.textSecondary),
      labelSmall: AppTextStyles.caption.copyWith(color: p.textSecondary),
    );

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      dividerColor: p.divider,

      // The palette travels with the theme so widgets can resolve semantic
      // colours (success, warning, secondary text, borders) that ColorScheme
      // has no slot for, via `context.palette`.
      extensions: <ThemeExtension<dynamic>>[p],

      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h3.copyWith(color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: p.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? p.surface : AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: inputBorder(p.border, 1),
        enabledBorder: inputBorder(p.border, 1),
        // Cyan focus ring is 2.1:1 on white in light mode; WCAG needs 3:1.
        focusedBorder: inputBorder(isDark ? AppColors.ring : p.primary, 2),
        errorBorder: inputBorder(p.error, 1),
        focusedErrorBorder: inputBorder(p.error, 2),
        labelStyle: AppTextStyles.label.copyWith(color: p.textSecondary),
        floatingLabelStyle:
            AppTextStyles.label.copyWith(color: p.textSecondary),
        hintStyle: AppTextStyles.body.copyWith(color: p.textDisabled),
        helperStyle: AppTextStyles.small.copyWith(color: p.textSecondary),
        prefixStyle: AppTextStyles.body.copyWith(color: p.textPrimary),
        suffixStyle: AppTextStyles.body.copyWith(color: p.textPrimary),
        errorStyle: AppTextStyles.small.copyWith(color: p.error),
        iconColor: p.textSecondary,
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: p.surfaceVariant,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTextStyles.label,
          minimumSize: const Size(0, 48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.cyan : p.textPrimary,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          side: BorderSide(
              color: isDark ? AppColors.cyan : p.textPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppTextStyles.label,
          minimumSize: const Size(0, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.cyan : p.primary,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.labelSmall,
          minimumSize: const Size(0, 36),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? p.surface : AppColors.surface,
        selectedItemColor: isDark ? AppColors.gold : AppColors.primary,
        unselectedItemColor: p.textSecondary,
        selectedLabelStyle: AppTextStyles.captionMedium,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(color: p.textPrimary),
        contentTextStyle: AppTextStyles.body.copyWith(color: p.textSecondary),
      ),

      // The snackbar deliberately inverts against the page in light mode and
      // sits on a raised dark surface in dark mode, so its text colour is
      // pinned rather than taken from the palette.
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDarkRaised : AppColors.primary,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.textPrimaryDark),
        actionTextColor: isDark ? AppColors.gold : AppColors.cyan,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? p.surfaceVariant : AppColors.secondary,
        selectedColor: p.primary,
        labelStyle: AppTextStyles.small.copyWith(
          color: isDark ? p.textPrimary : AppColors.secondaryForeground,
        ),
        secondaryLabelStyle:
            AppTextStyles.small.copyWith(color: colorScheme.onPrimary),
        iconTheme: IconThemeData(color: p.textSecondary, size: 18),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        // On a brand-filled track the thumb takes the on-brand colour, so it
        // stays visible: white on navy in light, obsidian on gold in dark.
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.textOnBrand;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.border;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        side: BorderSide(color: p.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.border;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.surfaceVariant,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.2),
        valueIndicatorTextStyle:
            AppTextStyles.small.copyWith(color: p.textOnBrand),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceVariant,
        circularTrackColor: p.surfaceVariant,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.3),
        selectionHandleColor: p.primary,
      ),

      iconTheme: IconThemeData(color: p.textPrimary, size: 24),
      primaryIconTheme: IconThemeData(color: colorScheme.onPrimary, size: 24),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.surfaceDarkRaised : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle:
            AppTextStyles.small.copyWith(color: AppColors.textPrimaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: AppTextStyles.body.copyWith(color: p.textPrimary),
        subtitleTextStyle: AppTextStyles.small.copyWith(color: p.textSecondary),
        leadingAndTrailingTextStyle:
            AppTextStyles.small.copyWith(color: p.textSecondary),
        iconColor: p.textPrimary,
        textColor: p.textPrimary,
      ),

      // Overlay surfaces. These were unthemed, so menus, dropdowns and sheets
      // fell back to Material defaults whose text colour does not track this
      // palette. Autocomplete's suggestion list is one of them.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: AppTextStyles.body.copyWith(color: p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AppTextStyles.body.copyWith(color: p.textPrimary),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: p.textPrimary,
        collapsedTextColor: p.textPrimary,
        iconColor: p.textPrimary,
        collapsedIconColor: p.textPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? AppColors.gold : p.primary,
        unselectedLabelColor: p.textSecondary,
        indicatorColor: isDark ? AppColors.gold : p.primary,
        labelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle:
            AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w500),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.primary,
        headerForegroundColor: colorScheme.onPrimary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        dialBackgroundColor: p.surfaceVariant,
        hourMinuteColor: p.surfaceVariant,
        hourMinuteTextColor: p.textPrimary,
      ),
    );
  }
}
