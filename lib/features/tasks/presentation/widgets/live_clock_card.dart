import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/surface_3d.dart';

class LiveClockCard extends StatefulWidget {
  const LiveClockCard({super.key});

  @override
  State<LiveClockCard> createState() => _LiveClockCardState();
}

class _LiveClockCardState extends State<LiveClockCard>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  DateTime _now = DateTime.now();
  int _prevSecond = -1;

  late final AnimationController _secondCtrl;
  late Animation<Offset> _slideOut;
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeOut;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _secondCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _buildAnims();

    _ticker = createTicker((_) {
      final now = DateTime.now();
      if (now.second != _prevSecond) {
        _prevSecond = now.second;
        _secondCtrl.forward(from: 0);
        if (mounted) setState(() => _now = now);
      }
    })..start();
  }

  void _buildAnims() {
    _slideOut = Tween(begin: Offset.zero, end: const Offset(0, -1)).animate(
      CurvedAnimation(
        parent: _secondCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _slideIn = Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _secondCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _secondCtrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _secondCtrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  String get _hhmm => DateFormat('HH:mm').format(_now);
  String get _seconds => _now.second.toString().padLeft(2, '0');
  String get _prevSecondStr =>
      _prevSecond < 1 ? '00' : (_prevSecond - 1).toString().padLeft(2, '0');
  String get _amPm => DateFormat('a').format(_now);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Surface3D(
        color: theme.colorScheme.surfaceContainerLow,
        edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
        borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        depth: 6,
        borderRadius: 24,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── LIVE label row ──
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.priorityLow,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.priorityLow.withValues(alpha: 0.6),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.priorityLow,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _amPm,
                    style: GoogleFonts.orbitron(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── HH:MM — fills full card width dynamically ──
              FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.centerLeft,
                child: Text(
                  _hhmm,
                  style: GoogleFonts.orbitron(
                    fontSize: 180,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    height: 1,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── SEC 23   MS 123 — one row ──
              Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SEC label
                  Text(
                    'SEC',
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      color: AppTheme.mauve.withValues(alpha: 0.55),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Animated seconds value
                  SizedBox(
                    width: 44,
                    height: 28,
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: _secondCtrl,
                        builder: (_, __) => Stack(
                          children: [
                            FadeTransition(
                              opacity: _fadeOut,
                              child: SlideTransition(
                                position: _slideOut,
                                child: _TickText(
                                  text: _prevSecondStr,
                                  color: AppTheme.deepPlum,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _fadeIn,
                              child: SlideTransition(
                                position: _slideIn,
                                child: _TickText(
                                  text: _seconds,
                                  color: AppTheme.deepPlum,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Gap
                  const SizedBox(width: 24),

                  // MS label
                  Text(
                    'MS',
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      color: AppTheme.mauve.withValues(alpha: 0.55),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Milliseconds — isolated widget, fixed width
                  const _MsCounter(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TickText extends StatelessWidget {
  const _TickText({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1,
        letterSpacing: 1,
      ),
    );
  }
}

/// Separate StatefulWidget so only ms digits rebuild — parent stays still.
/// Fixed SizedBox prevents layout shift when digit count changes width.
class _MsCounter extends StatefulWidget {
  const _MsCounter();

  @override
  State<_MsCounter> createState() => _MsCounterState();
}

class _MsCounterState extends State<_MsCounter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _ms = DateTime.now().millisecond;
  int _prevBucket = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      final now = DateTime.now();
      final bucket = now.millisecond ~/ 50;
      if (bucket != _prevBucket) {
        _prevBucket = bucket;
        if (mounted) setState(() => _ms = now.millisecond);
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fixed width = width of "000" so layout never shifts
    return SizedBox(
      // width: 52,
      child: Text(
        _ms.toString().padLeft(3, '0'),
        style: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppTheme.mauve,
          height: 1,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
