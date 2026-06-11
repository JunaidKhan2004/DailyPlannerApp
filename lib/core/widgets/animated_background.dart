import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Full-screen slowly drifting orbs — mount once behind the entire scaffold.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final List<_OrbController> _orbs;

  static const _orbDefs = [
    _OrbDef(size: 220, color: AppTheme.deepPlum, opacity: 0.13, duration: 8000, dx: 0.10, dy: 0.06),
    _OrbDef(size: 160, color: AppTheme.mauve,    opacity: 0.11, duration: 11000, dx: 0.72, dy: 0.15),
    _OrbDef(size: 100, color: AppTheme.peach,    opacity: 0.09, duration: 9500,  dx: 0.85, dy: 0.55),
    _OrbDef(size: 130, color: AppTheme.dustyPink,opacity: 0.10, duration: 13000, dx: 0.30, dy: 0.75),
    _OrbDef(size: 80,  color: AppTheme.mauve,    opacity: 0.08, duration: 7500,  dx: 0.55, dy: 0.40),
    _OrbDef(size: 60,  color: AppTheme.peach,    opacity: 0.12, duration: 10000, dx: 0.20, dy: 0.30),
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random(42);
    _orbs = _orbDefs.map((def) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: def.duration),
      )..repeat(reverse: true);
      // randomise start phase so they don't all move in sync
      ctrl.value = rng.nextDouble();
      return _OrbController(def: def, ctrl: ctrl);
    }).toList();
  }

  @override
  void dispose() {
    for (final o in _orbs) {
      o.ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: Listenable.merge(_orbs.map((o) => o.ctrl).toList()),
          builder: (context, _) {
            final size = MediaQuery.sizeOf(context);
            return Stack(
              children: _orbs.map((o) {
                final t = o.ctrl.value;
                // Gentle sine drift: each orb oscillates 6–10 % of screen
                final dx = o.def.dx * size.width +
                    sin(t * pi) * size.width * 0.07;
                final dy = o.def.dy * size.height +
                    cos(t * pi) * size.height * 0.06;
                return Positioned(
                  left: dx - o.def.size / 2,
                  top: dy - o.def.size / 2,
                  child: Container(
                    width: o.def.size,
                    height: o.def.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: o.def.color
                          .withValues(alpha: o.def.opacity),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _OrbDef {
  const _OrbDef({
    required this.size,
    required this.color,
    required this.opacity,
    required this.duration,
    required this.dx,
    required this.dy,
  });

  final double size;
  final Color color;
  final double opacity;
  final int duration;

  /// Fractional initial position (0–1) relative to screen.
  final double dx;
  final double dy;
}

class _OrbController {
  const _OrbController({required this.def, required this.ctrl});
  final _OrbDef def;
  final AnimationController ctrl;
}
