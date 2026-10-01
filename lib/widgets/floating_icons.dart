import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One icon drifting inside [FloatingIcons].
class FloatingIcon {
  const FloatingIcon({
    required this.icon,
    required this.left,
    required this.top,
    this.size = 28,
    this.opacity = 0.22,
    this.phase = 0,
    this.drift = 8,
  });

  final IconData icon;

  /// Position inside the box, 0 to 1 on each axis.
  final double left;
  final double top;

  final double size;
  final double opacity;

  /// Offset into the cycle, so icons do not all move together.
  final double phase;

  /// How far it drifts, in logical pixels.
  final double drift;
}

/// Softly drifting icons, for the empty side of a hero banner.
///
/// Drawn rather than loaded: no asset to ship, nothing to fetch, and it works
/// offline. Movement is slow and small, so it decorates without competing
/// with the text beside it.
///
/// Honours the platform's "reduce motion" setting: when that is on the icons
/// are drawn in their resting positions and the animation never starts, so
/// nobody who has asked for stillness gets movement anyway.
class FloatingIcons extends StatefulWidget {
  const FloatingIcons({
    super.key,
    required this.icons,
    this.colour = Colors.white,
    this.period = const Duration(seconds: 6),
  });

  final List<FloatingIcon> icons;
  final Color colour;

  /// One full drift cycle.
  final Duration period;

  /// Global off switch for the drift.
  ///
  /// A repeating animation never lets `pumpAndSettle` return, so any widget
  /// test touching a screen with a banner would hang. Test setup turns this
  /// off; production leaves it on. The icons still render, just at rest.
  static bool animationsEnabled = true;

  /// A set that suits a food or restaurant banner.
  static const food = [
    FloatingIcon(icon: Icons.ramen_dining, left: 0.12, top: 0.18, size: 34),
    FloatingIcon(
      icon: Icons.local_cafe,
      left: 0.58,
      top: 0.08,
      size: 26,
      phase: 0.3,
    ),
    FloatingIcon(
      icon: Icons.restaurant,
      left: 0.78,
      top: 0.48,
      size: 30,
      phase: 0.6,
    ),
    FloatingIcon(
      icon: Icons.lunch_dining,
      left: 0.3,
      top: 0.62,
      size: 28,
      phase: 0.45,
      opacity: 0.18,
    ),
    FloatingIcon(
      icon: Icons.icecream,
      left: 0.05,
      top: 0.72,
      size: 22,
      phase: 0.8,
      opacity: 0.16,
    ),
  ];

  /// A set that suits an AI or assistant banner.
  static const sparkles = [
    FloatingIcon(icon: Icons.auto_awesome, left: 0.08, top: 0.2, size: 24),
    FloatingIcon(
      icon: Icons.bolt,
      left: 0.46,
      top: 0.1,
      size: 20,
      phase: 0.35,
      opacity: 0.18,
    ),
    FloatingIcon(
      icon: Icons.chat_bubble_outline,
      left: 0.7,
      top: 0.55,
      size: 22,
      phase: 0.65,
      opacity: 0.16,
    ),
  ];

  @override
  State<FloatingIcons> createState() => _FloatingIconsState();
}

class _FloatingIconsState extends State<FloatingIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read the accessibility setting here rather than in initState, because
    // it comes from MediaQuery and can change while the screen is open.
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        !FloatingIcons.animationsEnabled;
    if (reduceMotion) {
      if (_started) {
        _controller.stop();
        _started = false;
      }
    } else if (!_started) {
      _controller.repeat();
      _started = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          children: [
            for (final item in widget.icons)
              Positioned(
                left: item.left * constraints.maxWidth,
                // A sine wave gives a smooth loop with no jump at the seam,
                // which a linear up-and-down would have.
                top:
                    item.top * constraints.maxHeight +
                    math.sin(
                          (_controller.value + item.phase) * 2 * math.pi,
                        ) *
                        item.drift,
                child: Opacity(
                  opacity: item.opacity,
                  child: Icon(
                    item.icon,
                    size: item.size,
                    color: widget.colour,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
