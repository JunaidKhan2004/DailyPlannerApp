import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/appwrite_service.dart';
import 'core/services/notification_service.dart';
import 'features/tasks/data/models/task_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive (local DB — primary source of truth)
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  await Hive.openBox<TaskModel>(AppConstants.tasksBox);

  // Notifications
  await NotificationService.init();
  await NotificationService.requestPermissions();

  // Appwrite (no-op until PROJECT_ID is filled in)
  await AppwriteService.init();

  runApp(const ProviderScope(child: DailyPlannerApp()));
}
