import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../providers/language_provider.dart';

/// The app's single error surface: a message plus an optional retry.
///
/// It used to paint raw `Colors.red` and label its retry button with a
/// hardcoded English 'Retry', so it was both invisible to the theme and
/// untranslated. Both now come from the app -- `palette.error` follows
/// light/dark, and the tooltip is a translation key -- because this is the
/// widget every screen is expected to use for a failed load.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final retryLabel = context.watch<LanguageProvider>().t('retry');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: 0.1),
        border: Border.all(color: palette.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: palette.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: Icon(Icons.refresh, color: palette.error),
              onPressed: onRetry,
              tooltip: retryLabel,
            ),
        ],
      ),
    );
  }
}

/// A full-panel failure state, for when a load failed and there is no content
/// to fall back to.
///
/// [ErrorBanner] sits above existing content; this replaces it. Without this,
/// screens that only render on success (the admin dashboard was one) collapse
/// to a blank panel when the request fails -- no message, no way back.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lang = context.watch<LanguageProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: palette.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(lang.t('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
