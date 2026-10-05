import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/network_status.dart';
import '../providers/language_provider.dart';

/// A strip pinned under the status bar while the backend is unreachable.
///
/// Without it, a failed request is indistinguishable from an empty result:
/// the user sees a blank list and no reason for it. One app-level surface is
/// enough -- individual screens keep their own error states for failures that
/// are not connectivity.
///
/// Wrap the app's `child` in [MaterialApp.builder] so it rides above every
/// route, including pushed ones.
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _Strip(),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkStatus.instance,
      builder: (context, _) {
        final offline = !NetworkStatus.instance.isOnline;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          offset: offline ? Offset.zero : const Offset(0, -1),
          child: IgnorePointer(
            ignoring: !offline,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: offline ? 1 : 0,
              child: Material(
                color: context.palette.error,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 16,
                          color: context.palette.textOnBrand,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.watch<LanguageProvider>().t('offline_banner'),
                            style: TextStyle(
                              color: context.palette.textOnBrand,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
