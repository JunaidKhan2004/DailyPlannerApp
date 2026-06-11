import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  /// Strips the time component so dates can be compared by day.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String formatFullDate(DateTime date) =>
      DateFormat('EEEE, d MMMM yyyy').format(date);

  static String formatShortDate(DateTime date) =>
      DateFormat('d MMM yyyy').format(date);

  static String formatTimeFromMinutes(int minutes) {
    final dt = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    return DateFormat('h:mm a').format(dt);
  }

  static String headerForDate(DateTime date) {
    final today = dateOnly(DateTime.now());
    final d = dateOnly(date);
    if (d == today) return 'Today';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatFullDate(date);
  }
}
