import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/presentation/screens/add_edit_task_screen.dart';
import '../../features/tasks/presentation/screens/home_screen.dart';
import '../../features/tasks/presentation/screens/search_screen.dart';
import '../../features/pomodoro/screens/pomodoro_screen.dart';

abstract class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home      = '/';
  static const String newTask   = '/task/new';
  static const String editTask  = '/task/edit';
  static const String search    = '/search';
  static const String settings  = '/settings';
  static const String stats     = '/stats';
  static const String pomodoro  = '/pomodoro';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_complete') ?? false;
      if (!done && state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
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
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.pomodoro,
        builder: (context, state) => const PomodoroScreen(),
      ),
    ],
  );
});
