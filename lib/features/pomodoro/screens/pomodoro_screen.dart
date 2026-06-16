import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/surface_3d.dart';

// ── State & logic ─────────────────────────────────────────────────────────────

enum _Phase { focus, shortBreak, longBreak }

class _PomodoroState {
  const _PomodoroState({
    required this.phase,
    required this.secondsLeft,
    required this.isRunning,
    required this.completedPomodoros,
  });

  final _Phase phase;
  final int secondsLeft;
  final bool isRunning;
  final int completedPomodoros;

  static const focusDuration      = 25 * 60;
  static const shortBreakDuration = 5 * 60;
  static const longBreakDuration  = 15 * 60;

  int get totalSeconds => switch (phase) {
        _Phase.focus      => focusDuration,
        _Phase.shortBreak => shortBreakDuration,
        _Phase.longBreak  => longBreakDuration,
      };

  double get progress => 1 - secondsLeft / totalSeconds;

  String get timeLabel {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  _PomodoroState copyWith({
    _Phase? phase,
    int? secondsLeft,
    bool? isRunning,
    int? completedPomodoros,
  }) =>
      _PomodoroState(
        phase: phase ?? this.phase,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        isRunning: isRunning ?? this.isRunning,
        completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      );
}

class _PomodoroNotifier extends StateNotifier<_PomodoroState> {
  _PomodoroNotifier()
      : super(const _PomodoroState(
          phase: _Phase.focus,
          secondsLeft: _PomodoroState.focusDuration,
          isRunning: false,
          completedPomodoros: 0,
        ));

  Timer? _timer;

  void toggle() {
    if (state.isRunning) {
      _timer?.cancel();
      NotificationService.cancelPomodoroEnd();
      state = state.copyWith(isRunning: false);
    } else {
      state = state.copyWith(isRunning: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      final label = switch (state.phase) {
        _Phase.focus      => 'Focus',
        _Phase.shortBreak => 'Short Break',
        _Phase.longBreak  => 'Long Break',
      };
      NotificationService.schedulePomodoroEnd(
        secondsFromNow: state.secondsLeft,
        phaseLabel: label,
      );
    }
  }

  void _tick() {
    if (state.secondsLeft <= 1) {
      _timer?.cancel();
      final completed = state.phase == _Phase.focus
          ? state.completedPomodoros + 1
          : state.completedPomodoros;
      final nextPhase = state.phase == _Phase.focus
          ? (completed % 4 == 0 ? _Phase.longBreak : _Phase.shortBreak)
          : _Phase.focus;
      final nextSecs = switch (nextPhase) {
        _Phase.focus      => _PomodoroState.focusDuration,
        _Phase.shortBreak => _PomodoroState.shortBreakDuration,
        _Phase.longBreak  => _PomodoroState.longBreakDuration,
      };
      state = _PomodoroState(
        phase: nextPhase,
        secondsLeft: nextSecs,
        isRunning: false,
        completedPomodoros: completed,
      );
    } else {
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    }
  }

  void setPhase(_Phase phase) {
    _timer?.cancel();
    NotificationService.cancelPomodoroEnd();
    final secs = switch (phase) {
      _Phase.focus      => _PomodoroState.focusDuration,
      _Phase.shortBreak => _PomodoroState.shortBreakDuration,
      _Phase.longBreak  => _PomodoroState.longBreakDuration,
    };
    state = _PomodoroState(
      phase: phase,
      secondsLeft: secs,
      isRunning: false,
      completedPomodoros: state.completedPomodoros,
    );
  }

  void reset() {
    _timer?.cancel();
    NotificationService.cancelPomodoroEnd();
    final secs = switch (state.phase) {
      _Phase.focus      => _PomodoroState.focusDuration,
      _Phase.shortBreak => _PomodoroState.shortBreakDuration,
      _Phase.longBreak  => _PomodoroState.longBreakDuration,
    };
    state = state.copyWith(secondsLeft: secs, isRunning: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final _pomodoroProvider =
    StateNotifierProvider<_PomodoroNotifier, _PomodoroState>(
  (_) => _PomodoroNotifier(),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  Color _color(_Phase p) => switch (p) {
        _Phase.focus      => AppTheme.deepPlum,
        _Phase.shortBreak => const Color(0xFF2E7D32),
        _Phase.longBreak  => const Color(0xFF1565C0),
      };

  Color _colorLight(_Phase p) => switch (p) {
        _Phase.focus      => AppTheme.mauve,
        _Phase.shortBreak => const Color(0xFF4CAF50),
        _Phase.longBreak  => const Color(0xFF5B8DEF),
      };

  String _label(_Phase p) => switch (p) {
        _Phase.focus      => 'Focus Time',
        _Phase.shortBreak => 'Short Break',
        _Phase.longBreak  => 'Long Break',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme    = Theme.of(context);
    final pomo     = ref.watch(_pomodoroProvider);
    final notifier = ref.read(_pomodoroProvider.notifier);
    final color    = _color(pomo.phase);
    final colorLight = _colorLight(pomo.phase);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            const AnimatedBackground(),
            SafeArea(
              child: Column(
                children: [

                  // ── Header card (same style as rest of app) ──────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Surface3D(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, colorLight],
                      ),
                      edgeColor: Surface3D.darken(color, 0.4),
                      depth: 7,
                      borderRadius: 28,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pomodoro Timer',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: Colors.white
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    child: Text(
                                      _label(pomo.phase),
                                      key: ValueKey(pomo.phase),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 26,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Menu button
                            GestureDetector(
                              onTap: () => Scaffold.of(ctx).openDrawer(),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Iconsax.menu,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Phase tabs (Surface3D style) ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Surface3D(
                      color: theme.colorScheme.surfaceContainerLow,
                      edgeColor: AppTheme.dustyPink.withValues(alpha: 0.8),
                      borderColor: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                      depth: 4,
                      borderRadius: 18,
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _PhaseTab(
                            label: 'Focus',
                            isSelected: pomo.phase == _Phase.focus,
                            color: AppTheme.deepPlum,
                            onTap: () => notifier.setPhase(_Phase.focus),
                          ),
                          const SizedBox(width: 4),
                          _PhaseTab(
                            label: 'Short',
                            isSelected: pomo.phase == _Phase.shortBreak,
                            color: const Color(0xFF2E7D32),
                            onTap: () =>
                                notifier.setPhase(_Phase.shortBreak),
                          ),
                          const SizedBox(width: 4),
                          _PhaseTab(
                            label: 'Long',
                            isSelected: pomo.phase == _Phase.longBreak,
                            color: const Color(0xFF1565C0),
                            onTap: () =>
                                notifier.setPhase(_Phase.longBreak),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Unique segmented dot timer ────────────────────────────
                  _SegmentedTimer(
                    progress: pomo.progress,
                    timeLabel: pomo.timeLabel,
                    isRunning: pomo.isRunning,
                    color: colorLight,
                    darkColor: color,
                  ),

                  const Spacer(),

                  // ── Session tomato dots ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final cyclePos = pomo.completedPomodoros % 4;
                      final filled = pomo.completedPomodoros > 0 &&
                          (cyclePos == 0 || i < cyclePos);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: filled
                              ? colorLight.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: filled
                                ? colorLight.withValues(alpha: 0.5)
                                : theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: filled
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorLight.withValues(alpha: 0.7),
                                ),
                              )
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pomo.completedPomodoros == 0
                        ? 'Start your first session'
                        : '${pomo.completedPomodoros} session${pomo.completedPomodoros == 1 ? '' : 's'} done',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Controls ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Reset button
                        Surface3D(
                          color: theme.colorScheme.surfaceContainerLow,
                          edgeColor:
                              AppTheme.dustyPink.withValues(alpha: 0.9),
                          borderColor: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                          depth: 5,
                          borderRadius: 18,
                          padding: const EdgeInsets.all(17),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            notifier.reset();
                          },
                          child: Icon(Iconsax.refresh,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 14),
                        // Play / Pause button
                        Expanded(
                          child: Surface3D(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, colorLight],
                            ),
                            edgeColor: Surface3D.darken(color, 0.4),
                            depth: 7,
                            borderRadius: 20,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              notifier.toggle();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Icon(
                                    pomo.isRunning
                                        ? Iconsax.pause
                                        : Iconsax.play,
                                    key: ValueKey(pomo.isRunning),
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Text(
                                    pomo.isRunning
                                        ? 'Pause'
                                        : 'Start Session',
                                    key: ValueKey(pomo.isRunning),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented dot timer ───────────────────────────────────────────────────────

class _SegmentedTimer extends StatefulWidget {
  const _SegmentedTimer({
    required this.progress,
    required this.timeLabel,
    required this.isRunning,
    required this.color,
    required this.darkColor,
  });

  final double progress;
  final String timeLabel;
  final bool isRunning;
  final Color color;
  final Color darkColor;

  @override
  State<_SegmentedTimer> createState() => _SegmentedTimerState();
}

class _SegmentedTimerState extends State<_SegmentedTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didUpdateWidget(_SegmentedTimer old) {
    super.didUpdateWidget(old);
    if (widget.isRunning && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isRunning) {
      _pulseCtrl.animateTo(0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final pulse = _pulseCtrl.value;
        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              if (widget.isRunning)
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color
                            .withValues(alpha: 0.08 + pulse * 0.14),
                        blurRadius: 30 + pulse * 25,
                        spreadRadius: pulse * 6,
                      ),
                    ],
                  ),
                ),

              // Segmented dot ring
              CustomPaint(
                size: const Size(260, 260),
                painter: _SegmentPainter(
                  progress: widget.progress,
                  activeColor: widget.color,
                  inactiveColor: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.2),
                  glowColor:
                      widget.color.withValues(alpha: 0.3 + pulse * 0.4),
                  totalSegments: 60,
                ),
              ),

              // Inner card
              Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Time
                    Text(
                      widget.timeLabel,
                      style: GoogleFonts.orbitron(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress pill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${((1 - widget.progress) * 100).round()}% left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Segment painter ───────────────────────────────────────────────────────────

class _SegmentPainter extends CustomPainter {
  const _SegmentPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.glowColor,
    required this.totalSegments,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color glowColor;
  final int totalSegments;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2 - 4;
    final innerR = outerR - 16;

    final filledCount = (progress * totalSegments).round();

    for (int i = 0; i < totalSegments; i++) {
      // Start from top (-π/2), go clockwise
      final angle = -math.pi / 2 + (i / totalSegments) * math.pi * 2;
      final gapAngle = (math.pi * 2 / totalSegments) * 0.18;
      final sweepAngle = (math.pi * 2 / totalSegments) - gapAngle;

      final isActive = i < filledCount;
      final isNext   = i == filledCount; // segment being filled right now

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      if (isActive) {
        // Glow for last few active segments
        if (i >= filledCount - 3 && filledCount > 3) {
          canvas.drawArc(
            Rect.fromCircle(
                center: Offset(cx, cy),
                radius: (outerR + innerR) / 2),
            angle + gapAngle / 2,
            sweepAngle,
            false,
            Paint()
              ..color = glowColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 14
              ..strokeCap = StrokeCap.round
              ..maskFilter =
                  const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
        paint.color = activeColor;
      } else if (isNext && progress > 0) {
        paint.color =
            Color.lerp(inactiveColor, activeColor, 0.4)!;
      } else {
        paint.color = inactiveColor;
      }

      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(cx, cy), radius: (outerR + innerR) / 2),
        angle + gapAngle / 2,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.glowColor != glowColor;
}

// ── Phase tab (Surface3D style) ───────────────────────────────────────────────

class _PhaseTab extends StatelessWidget {
  const _PhaseTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Surface3D(
        color: isSelected ? color : Colors.transparent,
        edgeColor:
            isSelected ? Surface3D.darken(color, 0.3) : Colors.transparent,
        depth: isSelected ? 4 : 0,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 11),
        onTap: onTap,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
