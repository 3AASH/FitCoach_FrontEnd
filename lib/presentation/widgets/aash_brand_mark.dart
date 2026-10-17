import 'package:flutter/material.dart';

/// The Aash (عاش) logo. Uses the navy/teal script on light surfaces and the
/// metallic-gold/light-blue variant on dark surfaces.
class AashBrandMark extends StatelessWidget {
  const AashBrandMark({
    super.key,
    this.size = 104,
    this.showWordmark = true,
    this.foregroundColor,
    this.brightness,
  });

  /// Logo height in logical pixels (the artwork is ~1.7:1).
  final double size;

  /// Kept for call-site compatibility: the wordmark is part of the artwork.
  final bool showWordmark;

  /// Kept for call-site compatibility; use [brightness] to force a variant.
  final Color? foregroundColor;

  /// Forces a variant regardless of the ambient theme (e.g. on a fixed
  /// dark hero background).
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final isDark =
        (brightness ?? Theme.of(context).brightness) == Brightness.dark;
    return Semantics(
      label: 'Aash',
      image: true,
      child: Image.asset(
        isDark
            ? 'assets/images/aash_logo_dark.png'
            : 'assets/images/aash_logo_light.png',
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
