import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final double initialScale;

  const AnimatedReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    // Use a 1 second animation so reveals are clearly visible
    this.duration = const Duration(milliseconds: 1000),
    this.offset = const Offset(0, 0.12),
    this.curve = Curves.easeOutCubic,
    this.initialScale = 0.94,
  });

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  bool _visible = false;
  bool _pendingReveal = false;
  Timer? _delayTimer;
  bool _frameCallbackScheduled = false;
  bool _delayStarted = false;

  @override
  void initState() {
    super.initState();
    // Don't start the delay timer until the widget is actually allowed to tick.
    // (Important for tabs/IndexedStack/Offstage where the widget can be built
    // offscreen and otherwise consume its delay before the user ever sees it.)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startDelayIfNeeded();
    _maybeReveal();
  }

  void _startDelayIfNeeded() {
    if (_delayStarted || !mounted) return;

    // Only start counting the delay once tickers are enabled for this subtree.
    if (!TickerMode.of(context)) return;

    _delayStarted = true;
    if (widget.delay == Duration.zero) {
      _pendingReveal = true;
      _maybeReveal();
      return;
    }

    _delayTimer = Timer(widget.delay, () {
      if (!mounted) return;
      _pendingReveal = true;
      _maybeReveal();
    });
  }

  void _maybeReveal() {
    if (!mounted || _visible || !_pendingReveal) return;

    // Important for IndexedStack/Offstage: when not visible, Flutter disables
    // tickers via TickerMode, which prevents implicit animations from running.
    // If we flip `_visible` while offstage, the animation is effectively skipped.
    if (!TickerMode.of(context)) {
      _scheduleRevealCheck();
      return;
    }

    setState(() {
      _visible = true;
      _pendingReveal = false;
    });
  }

  void _scheduleRevealCheck() {
    if (_frameCallbackScheduled) return;
    _frameCallbackScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _frameCallbackScheduled = false;
      _maybeReveal();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickerActive = TickerMode.of(context);
    if (tickerActive) {
      _startDelayIfNeeded();
    }
    if (tickerActive && _pendingReveal && !_visible) {
      _scheduleRevealCheck();
    }
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : widget.offset,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedScale(
          scale: _visible ? 1 : widget.initialScale,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
