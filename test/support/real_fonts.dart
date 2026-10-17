// Loads the app's bundled fonts for widget tests that measure layout.
import 'package:flutter/services.dart';

/// The test binary draws every glyph in Ahem, which is square and far wider
/// than the real fonts, so it would report overflows that never reach a user.
/// Load the app's bundled fonts instead. Body text uses the theme's default
/// family (Roboto on Android), which is not bundled, so Inter is registered
/// under that name: slightly wider than Roboto, so this errs on the side of
/// reporting an overflow.
Future<void> loadRealFonts() async {
  const families = {
    'Roboto': ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Bold.ttf'],
    'Inter': ['assets/fonts/Inter-Regular.ttf', 'assets/fonts/Inter-Bold.ttf'],
    'SpaceGrotesk': [
      'assets/fonts/SpaceGrotesk-Regular.ttf',
      'assets/fonts/SpaceGrotesk-Medium.ttf',
      'assets/fonts/SpaceGrotesk-Bold.ttf',
    ],
    'Cairo': ['assets/fonts/Cairo-Regular.ttf', 'assets/fonts/Cairo-Bold.ttf'],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}
