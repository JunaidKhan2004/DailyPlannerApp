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
