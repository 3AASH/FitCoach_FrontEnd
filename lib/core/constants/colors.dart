import 'package:flutter/material.dart';

/// Aash brand color primitives (Kinetic Luxury design system), shared by the
/// app theme and feature screens.
///
/// Light theme: porcelain canvas, deep-navy actions, gold milestones.
/// Dark theme: obsidian navy canvas, metallic-gold actions, cyan telemetry.
/// Prefer `context.palette` for anything that must flip between themes.
class AppColors {
  // Deep Navy: brand authority. Primary action fill in light mode.
  static const Color primary = Color(0xFF0A2540);
  static const Color primaryDark = Color(0xFF07192B);
  static const Color primaryLight = Color(0xFF38BDF8);

  // Slate tints for secondary chips and quiet fills.
  static const Color secondary = Color(0xFFE2E8F0);
  static const Color secondaryForeground = Color(0xFF0A2540);
  static const Color secondaryLight = Color(0xFFF1F5F9);

  // Rich Metallic Gold: achievements, streaks, dark-mode primary action.
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5C158);
  static const Color accent = gold;
  static const Color accentLight = goldLight;

  // Electric Cyan: live telemetry, focus, progress rings.
  static const Color cyan = Color(0xFF38BDF8);
  static const Color proteinDark = Color(0xFFB0C8EB);

  // Canvas and surfaces.
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF07192B);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color surfaceDark = Color(0xFF0F2D4A);
  static const Color surfaceDarkRaised = Color(0xFF1E3A5F);
  static const Color workoutBackground = Color(0xFFF8FAFC);

  // Text Colors
  static const Color textPrimary = Color(0xFF0A2540);
  static const Color textSecondary = Color(0xFF526174);
  static const Color textDisabled = Color(0xFF526174);
  static const Color textDisabledDark = Color(0xFFA6B6CB);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA6B6CB);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFB7791F);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1E3A5F);

  // Focus ring color (for accessibility)
  static const Color ring = Color(0xFF38BDF8);

  // Chart Colors
  static const Color chart1 = Color(0xFF0A2540);
  static const Color chart2 = Color(0xFF38BDF8);
  static const Color chart3 = Color(0xFFD4AF37);
  static const Color chart4 = Color(0xFF64748B);
  static const Color chart5 = Color(0xFF1E3A5F);

  // Brand gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1E3A5F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color headerGradientStart = Color(0xFF0A2540);
  static const Color headerGradientEnd = Color(0xFF07192B);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Corner radii: cards 16-24, controls 12-14, chips/pills fully rounded.
class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 24.0;
  static const double pill = 999.0;
}

/// Type scale. Headlines and labels use Space Grotesk, body text Inter; Arabic
/// glyphs fall back to Cairo.
class AppTextStyles {
  static const String headingFont = 'SpaceGrotesk';
  static const String bodyFont = 'Inter';
  static const List<String> arabicFallback = ['Cairo'];

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle smallMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Overline (all-caps labels, smallest)
  static const TextStyle overline = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: arabicFallback,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.8,
  );
}
