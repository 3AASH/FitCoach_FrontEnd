import 'package:flutter/material.dart';

/// App color constants matching the React app design system
class AppColors {
  // Primary Colors (from logo)
  static const Color primary = Color(0xFF3B82F6); // Blue
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  
  // Secondary Colors (from logo) - UPDATED to match React
  static const Color secondary = Color(0xFFE9D5FF); // Light purple background
  static const Color secondaryForeground = Color(0xFF7C5FDC); // Purple text
  static const Color secondaryLight = Color(0xFFE9D5FF);
  
  // Accent Colors (from logo)
  static const Color accent = Color(0xFFF59E0B); // Orange
  static const Color accentLight = Color(0xFFFBF24);
  
  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1F2937);
  static const Color surface = Color(0xFFF3F4F6);
  static const Color surfaceDark = Color(0xFF374151);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFd4183d); // UPDATED to match React
  static const Color info = Color(0xFF3B82F6);
  
  // Border & Divider
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFD1D5DB);
  
  // Focus ring color (for accessibility)
  static const Color ring = Color(0xFF7C5FDC); // Purple
  
  // Chart Colors
  static const Color chart1 = Color(0xFF3B82F6); // Blue
  static const Color chart2 = Color(0xFF7C5FDC); // Purple
  static const Color chart3 = Color(0xFFF59E0B); // Orange
  static const Color chart4 = Color(0xFF10B981); // Green
  static const Color chart5 = Color(0xFFEC4899); // Pink
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color headerGradientStart = Color(0xFF334155);
  static const Color headerGradientEnd = Color(0xFF0F172A);
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Border radius constants matching React design system
class AppRadius {
  static const double small = 6.0;   // rounded-md in React
  static const double medium = 10.0; // var(--radius) in React
  static const double large = 12.0;  // rounded-lg in React
  static const double xl = 14.0;     // rounded-xl in React
}

/// Text styles matching React typography
class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
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
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
}
