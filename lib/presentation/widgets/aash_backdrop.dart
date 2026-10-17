import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Drop-in [Scaffold] that shows the themed Aash background behind its body.
class AashScaffold extends StatelessWidget {
  const AashScaffold({
    super.key,
    this.appBar,
    this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.drawer,
    this.endDrawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  // Accepted for drop-in compatibility; the backdrop replaces it.
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const AashBackdrop(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
          bottomSheet: bottomSheet,
          drawer: drawer,
          endDrawer: endDrawer,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        ),
      ],
    );
  }
}

/// Screen background: the Aash pattern in the light theme, the plain
/// background colour in the dark theme.
class AashBackdrop extends StatelessWidget {
  const AashBackdrop({super.key, this.child});

  final Widget? child;

  static const asset = 'assets/images/backgrounds/aash_light_bg.jpg';
  static const darkAsset = 'assets/images/backgrounds/aash_dark_bg.jpg';

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.palette.background),
        Image.asset(
          isLight ? asset : darkAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        // Dims the dark pattern so cards and text stay readable over it.
        if (!isLight) ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        if (child != null) child!,
      ],
    );
  }
}
