import 'dart:async';
import 'dart:math';

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
import '../../../../core/widgets/surface_3d.dart';
import '../providers/task_providers.dart';
import '../widgets/live_clock_card.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '⛅';
    return '🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final tasks = ref.watch(tasksForSelectedDateProvider);
    final countByDay = ref.watch(taskCountByDayProvider);
    final calendarFormat = ref.watch(calendarFormatProvider);
    final doneCount = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
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
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(child: CustomScrollView(
          slivers: [
            // ── Rich Header ──
            SliverToBoxAdapter(
              child: _HomeHeader(
                greeting: _greeting(),
                emoji: _greetingEmoji(),
                done: doneCount,
                total: tasks.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Live clock ──
            const SliverToBoxAdapter(child: LiveClockCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Calendar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _CalendarFormatToggle(
                      format: calendarFormat,
                      onChanged: (f) =>
                          ref.read(calendarFormatProvider.notifier).state = f,
                    ),
                    const SizedBox(height: 10),
                    Surface3D(
                      color: theme.colorScheme.surfaceContainerLow,
                      edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
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
                        availableCalendarFormats: const {
                          CalendarFormat.week: 'Week',
                          CalendarFormat.month: 'Month',
                        },
                        onFormatChanged: (format) => ref
                            .read(calendarFormatProvider.notifier)
                            .state = format,
                        selectedDayPredicate: (day) =>
                            isSameDay(day, selectedDate),
                        onDaySelected: (selected, _) =>
                            ref.read(selectedDateProvider.notifier).state =
                                AppDateUtils.dateOnly(selected),
                        eventLoader: (day) => List.filled(
                            countByDay[AppDateUtils.dateOnly(day)] ?? 0,
                            null),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          weekendStyle: theme.textTheme.bodySmall!.copyWith(
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
                                color: theme.colorScheme.onSurfaceVariant),
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
                            color: Surface3D.darken(AppTheme.deepPlum, 0.1),
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
            ),

            // ── Section header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
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
            ),

            // ── Task list ──
            tasks.isEmpty
                ? const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TaskCard(task: tasks[index]),
                      childCount: tasks.length,
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        )),
        ],
      ),
    );
  }
}

// ── Header widget ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatefulWidget {
  const _HomeHeader({
    required this.greeting,
    required this.emoji,
    required this.done,
    required this.total,
  });

  final String greeting;
  final String emoji;
  final int done;
  final int total;

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader>
    with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();

    // ── Entry animation (900 ms total, staggered) ──
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _greetingFade = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _greetingSlide = Tween(begin: const Offset(-0.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic),
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
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllDone = widget.total > 0 && widget.done == widget.total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Surface3D(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepPlum, AppTheme.mauve],
        ),
        edgeColor: Surface3D.darken(AppTheme.deepPlum, 0.4),
        depth: 7,
        borderRadius: 28,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _SkyBody(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // Greeting — slides in slightly after emoji
                        FadeTransition(
                          opacity: _greetingFade,
                          child: SlideTransition(
                            position: _greetingSlide,
                            child: Text(
                              widget.greeting,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Date — fades in last on the left
                        FadeTransition(
                          opacity: _dateFade,
                          child: Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Ring — fades + scales in
                  FadeTransition(
                    opacity: _ringFade,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _entryCtrl,
                          curve: const Interval(0.4, 0.9,
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
                ],
              ),

              if (widget.total > 0) ...[
                const SizedBox(height: 18),

                // Status row — fades in with progress bar
                FadeTransition(
                  opacity: _dateFade,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Icon(
                          isAllDone ? Iconsax.tick_circle : Iconsax.flash_1,
                          key: ValueKey(isAllDone),
                          size: 14,
                          color: isAllDone
                              ? AppTheme.peach
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          isAllDone
                              ? 'All done — great job today!'
                              : '${widget.done} of ${widget.total} tasks completed',
                          key: ValueKey(isAllDone),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Animated progress bar
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.peach,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Surface3D.darken(AppTheme.peach, 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),         // _SkyBody
    ),           // ClipRRect
      ),         // Surface3D
    );           // Padding
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

// ── Sky body (sun / moon arc) ─────────────────────────────────────────────────

class _SkyBody extends StatefulWidget {
  const _SkyBody({required this.child});
  final Widget child;

  @override
  State<_SkyBody> createState() => _SkyBodyState();
}

class _SkyBodyState extends State<_SkyBody> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool get _isDay => _now.hour >= 6 && _now.hour < 18;

  double get _progress {
    final h = _now.hour;
    final m = _now.minute;
    if (_isDay) {
      return ((h - 6) * 60 + m) / (12 * 60);
    } else {
      final mins = h >= 18 ? (h - 18) * 60 + m : (h + 6) * 60 + m;
      return mins / (12 * 60);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress.clamp(0.0, 1.0);
    final isDay = _isDay;

    final orbColor = isDay ? const Color.fromARGB(137, 255, 209, 102) : const Color.fromARGB(149, 208, 216, 255);
    final glowColor = isDay ? const Color.fromARGB(151, 255, 183, 0) : const Color.fromARGB(126, 136, 153, 238);
    final icon = isDay ? Iconsax.sun_1 : Iconsax.moon;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final x = p * w;
        // Arc: stays in lower zone — peaks 44px from bottom at midpoint
        final bottomOffset = 10.0 + sin(p * pi) * 34.0;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: x - 22,
              bottom: bottomOffset,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // color: orbColor.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.10),
                      blurRadius: 15,
                      spreadRadius: 50,
                    ),
                  ],
                ),
                child: Icon(icon, color: orbColor, size: 50),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
