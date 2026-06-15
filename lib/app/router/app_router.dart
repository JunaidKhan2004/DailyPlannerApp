import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/pomodoro/screens/pomodoro_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/presentation/screens/add_edit_task_screen.dart';
import '../../features/tasks/presentation/screens/home_screen.dart';
import '../../features/tasks/presentation/screens/search_screen.dart';

abstract class AppRoutes {
  static const String login      = '/login';
  static const String onboarding = '/onboarding';
  static const String home       = '/';
  static const String newTask    = '/task/new';
  static const String editTask   = '/task/edit';
  static const String search     = '/search';
  static const String settings   = '/settings';
  static const String stats      = '/stats';
  static const String pomodoro   = '/pomodoro';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthChangeNotifier(),
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

      // Onboarding first
      if (!onboardingDone && state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      final User? user = authState.valueOrNull;
      final isOnLoginPage = state.matchedLocation == AppRoutes.login;

      // Not logged in → send to login (but allow guest via "continue without account")
      // We only redirect if user explicitly went to a protected route and is not logged in.
      // For now, login is optional — no forced redirect.
      if (user != null && isOnLoginPage) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
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

// Notifies GoRouter when Firebase auth state changes so redirect re-runs
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}
