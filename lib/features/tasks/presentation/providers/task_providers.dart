import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/utils/date_utils.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../data/sources/task_local_source.dart';
import '../../domain/repositories/task_repository.dart';

final taskLocalSourceProvider =
    Provider<TaskLocalSource>((ref) => TaskLocalSource());

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepositoryImpl(ref.watch(taskLocalSourceProvider)),
);

/// All tasks, live from Hive.
final tasksStreamProvider = StreamProvider<List<TaskModel>>(
  (ref) => ref.watch(taskRepositoryProvider).watchTasks(),
);

/// Week/month view of the home calendar.
final calendarFormatProvider =
    StateProvider<CalendarFormat>((ref) => CalendarFormat.week);

/// The day currently selected on the calendar.
final selectedDateProvider = StateProvider<DateTime>(
  (ref) => AppDateUtils.dateOnly(DateTime.now()),
);

/// Tasks for the selected day, pending first, then by time.
final tasksForSelectedDateProvider = Provider<List<TaskModel>>((ref) {
  final selected = ref.watch(selectedDateProvider);
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];

  final dayTasks = tasks
      .where((t) => AppDateUtils.isSameDay(t.dueDate, selected))
      .toList()
    ..sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final timeA = a.dueTimeMinutes ?? 24 * 60;
      final timeB = b.dueTimeMinutes ?? 24 * 60;
      if (timeA != timeB) return timeA.compareTo(timeB);
      return b.priority.index.compareTo(a.priority.index);
    });
  return dayTasks;
});

/// Live search query typed by the user.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Tasks for selected date, filtered by search query.
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final tasks = ref.watch(tasksForSelectedDateProvider);
  if (query.isEmpty) return tasks;
  return tasks
      .where((t) =>
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query))
      .toList();
});

/// Number of tasks per day — used for calendar event dots.
final taskCountByDayProvider = Provider<Map<DateTime, int>>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  final map = <DateTime, int>{};
  for (final t in tasks) {
    final day = AppDateUtils.dateOnly(t.dueDate);
    map[day] = (map[day] ?? 0) + 1;
  }
  return map;
});

// ── Stats ─────────────────────────────────────────────────────────────────────

class DayStats {
  const DayStats({required this.date, required this.total, required this.done});
  final DateTime date;
  final int total;
  final int done;
  double get rate => total == 0 ? 0 : done / total;
}

class AppStats {
  const AppStats({
    required this.todayTotal,
    required this.todayDone,
    required this.weekTotal,
    required this.weekDone,
    required this.streak,
    required this.last7,
    required this.allTimeTotal,
    required this.allTimeDone,
  });
  final int todayTotal, todayDone;
  final int weekTotal, weekDone;
  final int streak;
  final List<DayStats> last7;
  final int allTimeTotal, allTimeDone;

  double get weekRate => weekTotal == 0 ? 0 : weekDone / weekTotal;
  double get allTimeRate => allTimeTotal == 0 ? 0 : allTimeDone / allTimeTotal;
}

final appStatsProvider = Provider<AppStats>((ref) {
  final tasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
  final now = AppDateUtils.dateOnly(DateTime.now());

  // Today
  final todayTasks = tasks.where((t) => AppDateUtils.isSameDay(t.dueDate, now)).toList();

  // This week (Mon–Sun)
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final weekTasks = tasks
      .where((t) => !t.dueDate.isBefore(weekStart) && !t.dueDate.isAfter(weekEnd))
      .toList();

  // Streak — consecutive days going back from today with ≥1 completed task
  int streak = 0;
  var checkDay = now;
  while (true) {
    final dayDone = tasks
        .where((t) => AppDateUtils.isSameDay(t.dueDate, checkDay) && t.isCompleted)
        .length;
    if (dayDone == 0) break;
    streak++;
    checkDay = checkDay.subtract(const Duration(days: 1));
  }

  // Last 7 days
  final last7 = List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    final dayTasks = tasks.where((t) => AppDateUtils.isSameDay(t.dueDate, day)).toList();
    return DayStats(
      date: day,
      total: dayTasks.length,
      done: dayTasks.where((t) => t.isCompleted).length,
    );
  });

  return AppStats(
    todayTotal: todayTasks.length,
    todayDone: todayTasks.where((t) => t.isCompleted).length,
    weekTotal: weekTasks.length,
    weekDone: weekTasks.where((t) => t.isCompleted).length,
    streak: streak,
    last7: last7,
    allTimeTotal: tasks.length,
    allTimeDone: tasks.where((t) => t.isCompleted).length,
  );
});
