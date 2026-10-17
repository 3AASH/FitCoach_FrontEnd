import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';

/// Shrinks its child slightly while a finger is down, without taking part in
/// the gesture arena, so taps on the child still work.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.965});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Applies the "coverflow" look to a card based on its distance from the
/// focused position: [delta] is 0 when focused and +-1 one card away.
class MotionCard extends StatelessWidget {
  const MotionCard({
    super.key,
    required this.delta,
    required this.child,
    this.tilt = 0.14,
    this.minScale = 0.88,
    this.minOpacity = 0.6,
    this.lift = 14,
  });

  final double delta;
  final Widget child;
  final double tilt;
  final double minScale;
  final double minOpacity;
  final double lift;

  @override
  Widget build(BuildContext context) {
    final d = delta.clamp(-1.0, 1.0);
    final distance = d.abs();
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final scale = 1 - (1 - minScale) * distance;
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0011)
      ..rotateY(-d * tilt * sign)
      ..scaleByDouble(scale, scale, 1.0, 1.0)
      ..translateByDouble(0.0, lift * distance, 0.0, 1.0);
    return Opacity(
      opacity: 1 - (1 - minOpacity) * distance,
      child: Transform(
        alignment: Alignment.center,
        transform: matrix,
        child: child,
      ),
    );
  }
}

/// Slides and zooms a background image against the card's movement.
class ParallaxFill extends StatelessWidget {
  const ParallaxFill({
    super.key,
    required this.delta,
    required this.child,
    this.shift = 38,
    this.zoom = 1.2,
  });

  final double delta;
  final Widget child;
  final double shift;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final d = delta.clamp(-1.5, 1.5);
    final focus = 1 - d.abs().clamp(0.0, 1.0);
    return ClipRect(
      child: Transform.translate(
        offset: Offset(-d * shift * sign, 0),
        child: Transform.scale(
          // Focused cards settle slightly closer than their neighbours.
          scale: zoom - 0.06 * (1 - focus),
          child: child,
        ),
      ),
    );
  }
}

/// Slides a card in from the side and fades it up, [index]-staggered.
class _EntranceStagger extends StatelessWidget {
  const _EntranceStagger({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * 0.13, 0.5);
    final t =
        Interval(start, math.min(start + 0.5, 1.0), curve: Curves.easeOutBack)
            .transform(animation.value);
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(sign * (1 - t) * 90, (1 - t) * 18),
        child: Transform.scale(scale: 0.86 + 0.14 * t, child: child),
      ),
    );
  }
}

/// Swipeable card carousel with snapping, a staggered entrance, a 3D tilt and
/// parallax driven by [itemBuilder]'s `delta`, and an expanding dot indicator.
class MotionCarousel extends StatefulWidget {
  const MotionCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    this.viewportFraction = 0.84,
    this.showDots = true,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, double delta)
      itemBuilder;
  final double height;
  final double viewportFraction;
  final bool showDots;

  static const double dotsHeight = 22;

  @override
  State<MotionCarousel> createState() => _MotionCarouselState();
}

class _MotionCarouselState extends State<MotionCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pages =
      PageController(viewportFraction: widget.viewportFraction);
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _pages.dispose();
    _entrance.dispose();
    super.dispose();
  }

  double get _page {
    if (_pages.hasClients && _pages.position.haveDimensions) {
      return _pages.page ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pages,
            padEnds: false,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.itemCount,
            onPageChanged: (_) => HapticFeedback.selectionClick(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: Listenable.merge([_pages, _entrance]),
                builder: (context, _) {
                  final delta = index - _page;
                  return _EntranceStagger(
                    animation: _entrance,
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: MotionCard(
                        delta: delta,
                        child: widget.itemBuilder(context, index, delta),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (widget.showDots && widget.itemCount > 1)
          SizedBox(
            height: MotionCarousel.dotsHeight,
            child: AnimatedBuilder(
              animation: _pages,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.itemCount; i++)
                      Builder(builder: (context) {
                        final focus = (1 - (i - _page).abs()).clamp(0.0, 1.0);
                        return Container(
                          width: 7 + 17 * focus,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Color.lerp(
                                palette.border, palette.primary, focus),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Applies [MotionCard] to an item of a horizontal list driven by
/// [controller], where every item is [extent] wide including its gap.
class ScrollMotionItem extends StatelessWidget {
  const ScrollMotionItem({
    super.key,
    required this.controller,
    required this.index,
    required this.extent,
    required this.builder,
    this.minOpacity = 0.7,
  });

  final ScrollController controller;
  final int index;
  final double extent;
  final double minOpacity;
  final Widget Function(BuildContext context, double delta) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        final delta = (index * extent - offset) / extent;
        return MotionCard(
          delta: delta,
          minScale: 0.92,
          minOpacity: minOpacity,
          tilt: 0.1,
          lift: 8,
          child: builder(context, delta),
        );
      },
    );
  }
}

/// Eases a progress value up from zero when first shown, and between values
/// afterwards.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.minHeight = 8,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double minHeight;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: minHeight,
        backgroundColor: backgroundColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
