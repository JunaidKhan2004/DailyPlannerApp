import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/presentation/screens/add_edit_task_screen.dart';
import '../../features/tasks/presentation/screens/home_screen.dart';

abstract class AppRoutes {
  static const String home = '/';
  static const String newTask = '/task/new';
  static const String editTask = '/task/edit';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.newTask,
        builder: (context, state) =>
            AddEditTaskScreen(initialDate: state.extra as DateTime?),
      ),
      GoRoute(
        path: AppRoutes.editTask,
        builder: (context, state) =>
            AddEditTaskScreen(task: state.extra as TaskModel),
      ),
    ],
  );
});
