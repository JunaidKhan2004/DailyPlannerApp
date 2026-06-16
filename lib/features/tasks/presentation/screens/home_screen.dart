import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/animated_background.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/surface_3d.dart';
import '../providers/task_providers.dart';
import '../widgets/live_clock_card.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final tasks = ref.watch(tasksForSelectedDateProvider);
    final countByDay = ref.watch(taskCountByDayProvider);
    final calendarFormat = ref.watch(calendarFormatProvider);
    final doneCount = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      drawer: const AppDrawer(),
      floatingActionButton: Surface3D(
        gradient: const LinearGradient(
          colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
        ),
        edgeColor: Surface3D.darken(AppTheme.deepPlum, 0.35),
        depth: 6,
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: () => context.push(AppRoutes.newTask, extra: selectedDate),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'New Task',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) => Stack(
          children: [
            const AnimatedBackground(),
            SafeArea(
              child: NestedScrollView(
                // ── Header + Clock scroll away ──────────────────────────────
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: _HomeHeader(
                      done: doneCount,
                      total: tasks.length,
                      onMenu: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  const SliverToBoxAdapter(child: LiveClockCard()),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                ],
                // ── Calendar pinned + Tasks independently scrollable ────────
                body: Column(
                  children: [
                    // Calendar — fixed, always visible
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _CalendarFormatToggle(
                            format: calendarFormat,
                            onChanged: (f) => ref
                                .read(calendarFormatProvider.notifier)
                                .state = f,
                          ),
                          const SizedBox(height: 10),
                          Surface3D(
                            color: theme.colorScheme.surfaceContainerLow,
                            edgeColor:
                                AppTheme.dustyPink.withValues(alpha: 0.9),
                            borderColor: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                            depth: 6,
                            borderRadius: 20,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TableCalendar(
                              firstDay: DateTime(2020),
                              lastDay: DateTime(2035),
                              focusedDay: selectedDate,
                              calendarFormat: calendarFormat,
                              availableCalendarFormats: {
                                calendarFormat:
                                    calendarFormat == CalendarFormat.week
                                        ? 'Week'
                                        : 'Month',
                              },
                              onFormatChanged: (_) {},
                              selectedDayPredicate: (day) =>
                                  isSameDay(day, selectedDate),
                              onDaySelected: (selected, _) => ref
                                  .read(selectedDateProvider.notifier)
                                  .state = AppDateUtils.dateOnly(selected),
                              eventLoader: (day) => List.filled(
                                  countByDay[AppDateUtils.dateOnly(day)] ?? 0,
                                  null),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle:
                                    theme.textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                weekendStyle:
                                    theme.textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.priorityHigh
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: theme.textTheme.titleMedium!
                                    .copyWith(fontWeight: FontWeight.w800),
                                leftChevronIcon: Transform.flip(
                                  flipX: true,
                                  child: Icon(Iconsax.arrow_right_3,
                                      size: 20,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                                rightChevronIcon: Icon(Iconsax.arrow_right_3,
                                    size: 20,
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                              calendarStyle: CalendarStyle(
                                outsideDaysVisible: false,
                                selectedDecoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.gradientStart,
                                      AppTheme.gradientEnd,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Surface3D.darken(
                                          AppTheme.deepPlum, 0.35),
                                      offset: const Offset(0, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                selectedTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: AppTheme.peach.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                todayTextStyle: TextStyle(
                                  color: Surface3D.darken(
                                      AppTheme.deepPlum, 0.1),
                                  fontWeight: FontWeight.w800,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: AppTheme.mauve,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 3,
                                markerSize: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section header — fixed
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppDateUtils.headerForDate(selectedDate),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (tasks.isNotEmpty)
                            Surface3D(
                              color: AppTheme.dustyPink.withValues(alpha: 0.5),
                              edgeColor: AppTheme.mauve.withValues(alpha: 0.7),
                              depth: 3,
                              borderRadius: 20,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              child: Text(
                                '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Task list — independently scrollable
                    Expanded(
                      child: tasks.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 100),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) =>
                                  TaskCard(task: tasks[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header widget ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatefulWidget {
  const _HomeHeader({
    required this.done,
    required this.total,
    required this.onMenu,
  });

  final int done;
  final int total;
  final VoidCallback onMenu;

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader>
    with TickerProviderStateMixin {
  // Live clock for greeting
  late DateTime _now;
  late final Timer _clockTimer;

  String get _greeting {
    final h = _now.hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 21) return 'Good Evening';
    return 'Good Night';
  }

  // Staggered entry controllers
  late final AnimationController _entryCtrl;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _dateFade;
  late final Animation<double> _ringFade;

  // Progress bar controller — runs whenever done/total changes
  late final AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // Ring controller
  late final AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  // Floating sparkle pulse
  late final AnimationController _pulseCtrl;

  // Looping background animation (stars / clouds)
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // ── Entry animation (900 ms total, staggered) ──
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _greetingFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _greetingSlide = Tween(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    ));

    _dateFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _ringFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
    );

    // ── Progress bar ──
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final target = widget.total == 0 ? 0.0 : widget.done / widget.total;
    _progressAnim = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
    );

    // ── Ring fill ──
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringAnim = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic),
    );

    // ── Pulse (looping glow on ring when all done) ──
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // ── Background (looping) ──
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Kick off
    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _progressCtrl.forward();
        _ringCtrl.forward();
      }
    });
    if (widget.done == widget.total && widget.total > 0) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _pulseCtrl.repeat(reverse: true);
      });
    }
  }

  @override
  void didUpdateWidget(_HomeHeader old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done || old.total != widget.total) {
      final newTarget =
          widget.total == 0 ? 0.0 : widget.done / widget.total;
      final oldTarget =
          old.total == 0 ? 0.0 : old.done / old.total;

      _progressAnim =
          Tween<double>(begin: oldTarget, end: newTarget).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic),
      );
      _ringAnim = Tween<double>(begin: oldTarget, end: newTarget).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic),
      );

      _progressCtrl
        ..reset()
        ..forward();
      _ringCtrl
        ..reset()
        ..forward();

      if (widget.done == widget.total && widget.total > 0) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _pulseCtrl.repeat(reverse: true);
        });
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  int get _hour => _now.hour;

  LinearGradient get _timeGradient {
    if (_hour >= 5 && _hour < 12) {
      // Morning — soft sky blue
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1a6b8a), Color(0xFF2d9cdb)],
      );
    } else if (_hour >= 12 && _hour < 17) {
      // Afternoon — bright blue
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0052D4), Color(0xFF4364F7)],
      );
    } else if (_hour >= 17 && _hour < 21) {
      // Evening — sunset purple-orange
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6a0572), Color(0xFFc94b4b)],
      );
    } else {
      // Night — deep dark indigo
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0f0c29), Color(0xFF24243e)],
      );
    }
  }

  Color get _edgeColor {
    if (_hour >= 5 && _hour < 12) return const Color(0xFF0e4d66);
    if (_hour >= 12 && _hour < 17) return const Color(0xFF003a99);
    if (_hour >= 17 && _hour < 21) return const Color(0xFF4a0050);
    return const Color(0xFF07061a);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllDone = widget.total > 0 && widget.done == widget.total;
    final pct = widget.total == 0
        ? 0
        : ((widget.done / widget.total) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Surface3D(
        gradient: _timeGradient,
        edgeColor: _edgeColor,
        depth: 7,
        borderRadius: 28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Animated time-of-day background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _hour >= 5 && _hour < 12
                        ? _CloudPainter(_bgCtrl.value)
                        : _hour >= 12 && _hour < 17
                            ? _SunRayPainter(_bgCtrl.value)
                            : _hour >= 17 && _hour < 21
                                ? _ShootingStarPainter(_bgCtrl.value)
                                : _StarPainter(_bgCtrl.value),
                  ),
                ),
              ),
              Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Row 1: greeting + menu ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date chip
                        FadeTransition(
                          opacity: _dateFade,
                          child: Text(
                            DateFormat('EEEE, d MMMM').format(_now),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.55),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Greeting — slides up
                        FadeTransition(
                          opacity: _greetingFade,
                          child: SlideTransition(
                            position: _greetingSlide,
                            child: Text(
                              _greeting,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  GestureDetector(
                    onTap: widget.onMenu,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Iconsax.menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Row 2: ring + progress (only when tasks exist) ──────────
              if (widget.total > 0) ...[
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _dateFade,
                  child: Row(
                    children: [

                      // Ring
                      FadeTransition(
                        opacity: _ringFade,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _entryCtrl,
                              curve: const Interval(0.3, 0.9,
                                  curve: Curves.easeOutBack),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _ringAnim,
                            builder: (_, __) => _RingProgress(
                              progress: _ringAnim.value,
                              done: widget.done,
                              total: widget.total,
                              pulseCtrl: _pulseCtrl,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Progress bar + labels
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status text
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                isAllDone
                                    ? 'All done! Great work'
                                    : '$pct% completed',
                                key: ValueKey(isAllDone),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.done} of ${widget.total} tasks done',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress bar
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: AnimatedBuilder(
                                animation: _progressAnim,
                                builder: (_, __) => FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor:
                                      _progressAnim.value.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.peach,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.peach
                                              .withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),        // Column
        ),          // inner Padding
            ],      // Stack children
          ),        // Stack
        ),          // ClipRRect
      ),            // Surface3D
    );
  }
}

class _RingProgress extends StatelessWidget {
  const _RingProgress({
    required this.progress,
    required this.done,
    required this.total,
    required this.pulseCtrl,
  });

  final double progress;
  final int done;
  final int total;
  final AnimationController pulseCtrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllDone = total > 0 && done == total;

    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) {
        final glow = isAllDone ? pulseCtrl.value : 0.0;
        return Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: isAllDone
                ? [
                    BoxShadow(
                      color: AppTheme.peach.withValues(alpha: 0.3 + glow * 0.4),
                      blurRadius: 8 + glow * 14,
                      spreadRadius: glow * 4,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.peach),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                total == 0 ? '—' : '$done/$total',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (total > 0)
                Text(
                  'done',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Calendar format toggle ────────────────────────────────────────────────────

class _CalendarFormatToggle extends StatelessWidget {
  const _CalendarFormatToggle({
    required this.format,
    required this.onChanged,
  });

  final CalendarFormat format;
  final ValueChanged<CalendarFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Surface3D(
      color: theme.colorScheme.surfaceContainerLow,
      edgeColor: AppTheme.dustyPink.withValues(alpha: 0.8),
      borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      depth: 4,
      borderRadius: 18,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Week',
            icon: Iconsax.calendar_1,
            isSelected: format == CalendarFormat.week,
            onTap: () => onChanged(CalendarFormat.week),
          ),
          const SizedBox(width: 4),
          _ToggleOption(
            label: 'Month',
            icon: Iconsax.calendar_1,
            isSelected: format == CalendarFormat.month,
            onTap: () => onChanged(CalendarFormat.month),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Surface3D(
        color: isSelected ? AppTheme.deepPlum : Colors.transparent,
        edgeColor: isSelected
            ? Surface3D.darken(AppTheme.deepPlum, 0.35)
            : Colors.transparent,
        depth: isSelected ? 4 : 0,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 10),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Surface3D(
            color: AppTheme.peach.withValues(alpha: 0.7),
            edgeColor: Surface3D.darken(AppTheme.peach, 0.3),
            depth: 3,
            borderRadius: 28,
            padding: const EdgeInsets.all(22),
            child: Icon(
              Iconsax.coffee,
              size: 30,
              color: Surface3D.darken(AppTheme.deepPlum, 0.1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks for this day',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Enjoy your free time or plan something new',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Animated header background painters ──────────────────────────────────────

class _StarData {
  _StarData(math.Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        r = rng.nextDouble() * 1.4 + 0.4,
        phase = rng.nextDouble() * math.pi * 2,
        speed = rng.nextDouble() * 0.6 + 0.5;
  final double x, y, r, phase, speed;
}

final _stars = List.generate(
    48, (i) => _StarData(math.Random(i * 13 + 7)));

class _StarPainter extends CustomPainter {
  _StarPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      final opacity =
          ((math.sin(t * math.pi * 2 * s.speed + s.phase) + 1) / 2)
              .clamp(0.15, 1.0);
      paint.color = Colors.white.withValues(alpha: opacity * 0.85);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }
    // Moon glow top-right
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.18),
        size.width * 0.22, glowPaint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}

class _CloudData {
  _CloudData(int seed)
      : y = math.Random(seed).nextDouble() * 0.75 + 0.1,
        scale = math.Random(seed + 1).nextDouble() * 0.08 + 0.07,
        speed = math.Random(seed + 2).nextDouble() * 0.12 + 0.06;
  final double y, scale, speed;
}

final _clouds = List.generate(4, (i) => _CloudData(i * 11));

class _CloudPainter extends CustomPainter {
  _CloudPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.fill;

    for (final c in _clouds) {
      final x = ((t * c.speed + _clouds.indexOf(c) * 0.28) % 1.3 - 0.15) *
          size.width;
      final cy = c.y * size.height;
      final r = c.scale * size.width;
      _drawCloud(canvas, paint, x, cy, r);
    }

    // Sunrise glow bottom
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 1.1),
          radius: size.width * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  void _drawCloud(Canvas canvas, Paint p, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r, p);
    canvas.drawCircle(Offset(cx + r * 0.9, cy - r * 0.3), r * 0.75, p);
    canvas.drawCircle(Offset(cx + r * 1.7, cy), r * 0.65, p);
    canvas.drawCircle(Offset(cx + r * 0.5, cy - r * 0.55), r * 0.6, p);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.t != t;
}

class _SunRayPainter extends CustomPainter {
  _SunRayPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.88;
    final cy = -size.height * 0.1;
    const rayCount = 10;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2 +
          t * math.pi * 2 * 0.08; // slow rotation
      final opacity = ((math.sin(t * math.pi * 2 + i) + 1) / 2) * 0.18 + 0.04;
      paint.color = Colors.white.withValues(alpha: opacity);
      final innerR = size.width * 0.12;
      final outerR = size.width * (0.35 + math.sin(t * math.pi * 2 + i) * 0.05);
      canvas.drawLine(
        Offset(cx + math.cos(angle) * innerR, cy + math.sin(angle) * innerR),
        Offset(cx + math.cos(angle) * outerR, cy + math.sin(angle) * outerR),
        paint,
      );
    }
    // Sun core glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.14, glowPaint);
  }

  @override
  bool shouldRepaint(_SunRayPainter old) => old.t != t;
}

class _ShootingStarPainter extends CustomPainter {
  _ShootingStarPainter(this.t);
  final double t;

  static final _rng = math.Random(42);
  static final _shooters = List.generate(3, (i) {
    return {
      'delay': _rng.nextDouble(),
      'y': _rng.nextDouble() * 0.6,
      'len': 0.18 + _rng.nextDouble() * 0.14,
    };
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background stars (still)
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (final s in _stars) {
      dotPaint.color = Colors.white.withValues(alpha: 0.25);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height * 0.9), s.r * 0.7,
          dotPaint);
    }

    // Shooting stars
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final sh in _shooters) {
      final delay = sh['delay'] as double;
      final yFrac = sh['y'] as double;
      final len = sh['len'] as double;
      final localT = ((t + delay) % 1.0);
      if (localT > 0.6) continue;
      final progress = localT / 0.6;
      final startX = size.width * (1.1 - progress * 1.5);
      final startY = size.height * (yFrac + progress * 0.2);
      final endX = startX + size.width * len;
      final endY = startY - size.height * len * 0.3;
      final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);
      trailPaint.shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: opacity * 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(
          Offset(startX, startY), Offset(endX, endY)));
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), trailPaint);
    }
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) => old.t != t;
}

