import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/tasks/data/models/task_model.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // v2 channel — forces recreation with sound on devices that cached v1
  static const _channelId   = 'task_reminders_v2';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Reminders for your scheduled tasks';

  // Accent color matching AppTheme.deepPlum
  static const _accentColor = 0xFF574964;

  static Future<void> init() async {
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Unknown identifier — scheduling falls back to UTC
    }

    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> scheduleTaskReminder(TaskModel task) async {
    if (task.dueTimeMinutes == null) return;

    final hour   = task.dueTimeMinutes! ~/ 60;
    final minute = task.dueTimeMinutes! % 60;

    final localScheduled = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      hour,
      minute,
    );

    if (localScheduled.isBefore(DateTime.now())) return;

    final scheduledTime = tz.TZDateTime.from(localScheduled, tz.local);

    final body = task.description.isNotEmpty
        ? task.description
        : 'Time to work on this task!';

    final subText = '${_priorityLabel(task.priority)} priority  •  ${task.category.label}';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        color: const Color(_accentColor),
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: task.title,
          summaryText: subText,
        ),
        subText: subText,
        ticker: task.title,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[0, 250, 100, 250]),
        channelShowBadge: true,
        showWhen: true,
        when: scheduledTime.millisecondsSinceEpoch,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      task.id.hashCode,
      task.title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
  }

  // ── Pomodoro ──────────────────────────────────────────────────────────────

  static const _pomodoroNotifId = 9999;

  static Future<void> schedulePomodoroEnd({
    required int secondsFromNow,
    required String phaseLabel,
  }) async {
    await _plugin.cancel(_pomodoroNotifId);

    final scheduledTime = tz.TZDateTime.now(tz.local)
        .add(Duration(seconds: secondsFromNow));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        color: Color(_accentColor),
        icon: '@drawable/ic_notification',
        playSound: true,
        enableVibration: true,
        ticker: 'Pomodoro',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      _pomodoroNotifId,
      '$phaseLabel complete! 🎉',
      phaseLabel == 'Focus'
          ? 'Great work! Time for a break.'
          : 'Break over — let\'s get back to focus!',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelPomodoroEnd() async {
    await _plugin.cancel(_pomodoroNotifId);
  }

  static String _priorityLabel(TaskPriority p) => switch (p) {
        TaskPriority.high   => '🔴 High',
        TaskPriority.medium => '🟡 Medium',
        TaskPriority.low    => '🟢 Low',
      };
}
