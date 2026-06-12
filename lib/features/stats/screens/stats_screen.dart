import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/surface_3d.dart';
import '../../tasks/presentation/providers/task_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(appStatsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            const AnimatedBackground(),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // ── Header ──
                  SliverToBoxAdapter(
                    child: Padding(
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
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 20, 22),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, d MMMM')
                                          .format(DateTime.now()),
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Your Stats',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 28,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Scaffold.of(ctx).openDrawer(),
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
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Top stat cards ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.flash_1,
                              label: 'Streak',
                              value: '${stats.streak}',
                              sub: stats.streak == 1 ? 'day' : 'days',
                              color: AppTheme.priorityHigh,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.tick_circle,
                              label: 'Today',
                              value: '${stats.todayDone}',
                              sub: 'of ${stats.todayTotal} done',
                              color: AppTheme.mauve,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Iconsax.chart_2,
                              label: 'All Time',
                              value:
                                  '${(stats.allTimeRate * 100).round()}%',
                              sub: '${stats.allTimeDone} completed',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── This week summary ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Surface3D(
                        color: theme.colorScheme.surfaceContainerLow,
                        edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
                        borderColor: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                        depth: 5,
                        borderRadius: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Iconsax.calendar_2,
                                      size: 16, color: AppTheme.mauve),
                                  const SizedBox(width: 8),
                                  Text(
                                    'THIS WEEK',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.mauve,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${stats.weekDone} / ${stats.weekTotal} tasks',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Progress bar
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: stats.weekRate.clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.deepPlum,
                                          AppTheme.mauve
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                stats.weekTotal == 0
                                    ? 'No tasks this week yet'
                                    : '${(stats.weekRate * 100).round()}% completion rate',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Last 7 days bar chart ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Surface3D(
                        color: theme.colorScheme.surfaceContainerLow,
                        edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
                        borderColor: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                        depth: 5,
                        borderRadius: 20,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Iconsax.chart_square,
                                      size: 16, color: AppTheme.mauve),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LAST 7 DAYS',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.mauve,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _BarChart(days: stats.last7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── All-time totals ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TotalTile(
                              icon: Iconsax.note_2,
                              label: 'Total Created',
                              value: '${stats.allTimeTotal}',
                              color: const Color(0xFF5B8DEF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TotalTile(
                              icon: Iconsax.tick_square,
                              label: 'Completed',
                              value: '${stats.allTimeDone}',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TotalTile(
                              icon: Iconsax.clock,
                              label: 'Pending',
                              value:
                                  '${stats.allTimeTotal - stats.allTimeDone}',
                              color: AppTheme.priorityMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card (streak / today / all-time) ─────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Surface3D(
      color: theme.colorScheme.surfaceContainerLow,
      edgeColor: color.withValues(alpha: 0.5),
      borderColor: color.withValues(alpha: 0.2),
      depth: 5,
      borderRadius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  const _BarChart({required this.days});
  final List<DayStats> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxTotal = days.fold(0, (m, d) => d.total > m ? d.total : m);
    final today = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((d) {
        final isToday = d.date.day == today.day &&
            d.date.month == today.month &&
            d.date.year == today.year;
        final barH = maxTotal == 0 ? 0.0 : (d.total / maxTotal) * 100.0;
        final doneH = maxTotal == 0 || d.total == 0
            ? 0.0
            : (d.done / maxTotal) * 100.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                // Count label
                Text(
                  d.total == 0 ? '' : '${d.total}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? AppTheme.mauve
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                // Bar
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Total bar (background)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: double.infinity,
                        height: barH.clamp(4.0, 100.0),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.mauve.withValues(alpha: 0.15)
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Done bar (foreground)
                      if (d.done > 0)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          height: doneH.clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [AppTheme.deepPlum, AppTheme.mauve]
                                  : [
                                      AppTheme.mauve.withValues(alpha: 0.7),
                                      AppTheme.mauve.withValues(alpha: 0.4),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Day label
                Text(
                  DateFormat('E').format(d.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight:
                        isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday
                        ? AppTheme.mauve
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Total tile ────────────────────────────────────────────────────────────────

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Surface3D(
      color: theme.colorScheme.surfaceContainerLow,
      edgeColor: color.withValues(alpha: 0.4),
      borderColor: color.withValues(alpha: 0.15),
      depth: 4,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
