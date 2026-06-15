import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_auth_service.dart';
import 'confirm_dialog.dart';
import 'surface_3d.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Brand header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Surface3D(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.deepPlum, AppTheme.mauve],
                ),
                edgeColor: Surface3D.darken(AppTheme.deepPlum, 0.4),
                depth: 6,
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Avatar — photo if logged in, icon if guest
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: user?.photoURL != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoURL!,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Iconsax.user, color: Colors.white, size: 26),
                                ),
                              )
                            : const Icon(Iconsax.calendar_2,
                                color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Daily Planner',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? DateFormat('EEEE, d MMM').format(DateTime.now()),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Nav items ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _DrawerItem(
                      icon: Iconsax.home_2,
                      label: 'Home',
                      isSelected: currentRoute == AppRoutes.home,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != AppRoutes.home) {
                          context.go(AppRoutes.home);
                        }
                      },
                    ),
                    _DrawerItem(
                      icon: Iconsax.search_normal,
                      label: 'Search Tasks',
                      isSelected: currentRoute == AppRoutes.search,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.search);
                      },
                    ),
                    _DrawerItem(
                      icon: Iconsax.chart_square,
                      label: 'Stats',
                      isSelected: currentRoute == AppRoutes.stats,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.stats);
                      },
                    ),
                    _DrawerItem(
                      icon: Iconsax.timer_1,
                      label: 'Pomodoro',
                      isSelected: currentRoute == AppRoutes.pomodoro,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.pomodoro);
                      },
                    ),
                    _DrawerItem(
                      icon: Iconsax.setting_2,
                      label: 'Settings',
                      isSelected: currentRoute == AppRoutes.settings,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.settings);
                      },
                    ),

                    const Spacer(),

                    // ── Login / Logout ──
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _DrawerItem(
                        icon: user != null ? Iconsax.logout : Iconsax.login,
                        label: user != null ? 'Sign Out' : 'Sign In with Google',
                        isSelected: false,
                        onTap: () async {
                          if (user != null) {
                            Navigator.of(context).pop();
                            final confirmed = await showConfirmDialog(
                              context,
                              title: 'Sign Out',
                              message: 'Are you sure you want to sign out?',
                              confirmLabel: 'Sign Out',
                              icon: Iconsax.logout,
                              confirmColor: AppTheme.priorityHigh,
                            );
                            if (confirmed) {
                              await FirebaseAuthService.signOut();
                            }
                          } else {
                            Navigator.of(context).pop();
                            context.push(AppRoutes.login);
                          }
                        },
                      ),
                    ),

                    // ── Footer ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDark ? Iconsax.moon : Iconsax.sun_1,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'v1.0.0',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Surface3D(
        color: isSelected
            ? AppTheme.deepPlum
            : Colors.transparent,
        edgeColor: isSelected
            ? Surface3D.darken(AppTheme.deepPlum, 0.35)
            : Colors.transparent,
        borderColor: isSelected
            ? null
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.0),
        depth: isSelected ? 4 : 0,
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.peach,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
