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
  static ThemeData getLightTheme() => _build(AppPalette.light, Brightness.light);

  static ThemeData getDarkTheme() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: isDark ? AppColors.backgroundDark : Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: p.error,
      onError: Colors.white,
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
      labelMedium: AppTextStyles.labelSmall.copyWith(color: p.textSecondary),
      labelSmall: AppTextStyles.small.copyWith(color: p.textSecondary),
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
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: p.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: inputBorder(p.border, 1),
        enabledBorder: inputBorder(p.border, 1),
        focusedBorder: inputBorder(AppColors.ring, 2),
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
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.bodyMedium,
          minimumSize: const Size(0, 36), // h-9 in React
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          side: BorderSide(color: p.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.bodyMedium,
          minimumSize: const Size(0, 36),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          disabledForegroundColor: p.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.bodyMedium,
          minimumSize: const Size(0, 36),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? p.surfaceVariant : p.background,
        selectedItemColor: p.primary,
        unselectedItemColor: isDark ? p.textSecondary : AppColors.textDisabled,
        selectedLabelStyle: AppTextStyles.small,
        unselectedLabelStyle: AppTextStyles.small,
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
            isDark ? AppColors.surfaceDarkRaised : AppColors.backgroundDark,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.textPrimaryDark),
        actionTextColor: AppColors.primaryLight,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
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
        checkColor: const WidgetStatePropertyAll(Colors.white),
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
            AppTextStyles.small.copyWith(color: AppColors.textPrimaryDark),
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
          color: isDark ? AppColors.surfaceDarkRaised : AppColors.backgroundDark,
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
        labelColor: p.primary,
        unselectedLabelColor: p.textSecondary,
        labelStyle: AppTextStyles.smallMedium,
        unselectedLabelStyle: AppTextStyles.small,
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
