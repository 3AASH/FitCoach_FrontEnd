import 'package:flutter/material.dart';

/// Aash brand color primitives, shared by the app theme and feature screens.
class AppColors {
  // Deep teal signals grounded, everyday wellness.
  static const Color primary = Color(0xFF0B6254);
  static const Color primaryDark = Color(0xFF08483F);
  static const Color primaryLight = Color(0xFF54B99F);

  // Soft botanical surfaces.
  static const Color secondary = Color(0xFFE5F1E9);
  static const Color secondaryForeground = Color(0xFF0B6254);
  static const Color secondaryLight = Color(0xFFF1F5E8);

  // Sunlit lime is an accent, not a text-bearing button fill.
  static const Color accent = Color(0xFFC8E66A);
  static const Color accentLight = Color(0xFFE0F3A8);

  // Warm, low-glare neutrals.
  static const Color background = Color(0xFFF7F8F2);
  static const Color backgroundDark = Color(0xFF18332D);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF28443D);
  static const Color surfaceDarkRaised = Color(0xFF122923);
  static const Color workoutBackground = Color(0xFFF3F6EF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1D302A);
  static const Color textSecondary = Color(0xFF64756D);
  static const Color textDisabled = Color(0xFF9AA9A1);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF3F6F1);
  static const Color textSecondaryDark = Color(0xFFC0CEC6);

  // Status Colors
  static const Color success = Color(0xFF27835F);
  static const Color warning = Color(0xFF9A7418);
  static const Color error = Color(0xFFB93845);
  static const Color info = Color(0xFF287C70);

  // Border & Divider
  static const Color border = Color(0xFFDDE6DD);
  static const Color divider = Color(0xFFD1DDD3);
  static const Color borderDark = Color(0xFF405A51);

  // Focus ring color (for accessibility)
  static const Color ring = Color(0xFF318A78);

  // Chart Colors
  static const Color chart1 = Color(0xFF0B6254);
  static const Color chart2 = Color(0xFF54B99F);
  static const Color chart3 = Color(0xFFC8A943);
  static const Color chart4 = Color(0xFF77A96B);
  static const Color chart5 = Color(0xFFB67B86);

  // Brand gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color headerGradientStart = Color(0xFF0B6254);
  static const Color headerGradientEnd = Color(0xFF153F36);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Border radius constants matching React design system
class AppRadius {
  static const double small = 8.0; // Matches actual usage across 56 sites
  static const double medium = 12.0; // Most common, used 135+ times
  static const double large = 16.0; // Used 38+ times
  static const double pill = 999.0; // Full circle (height/2)
}

/// Text styles matching React typography
class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle smallMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  // Caption (smallest text, most common in app but was missing)
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.25,
  );

  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  // Overline (all-caps labels, smallest)
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );
}
