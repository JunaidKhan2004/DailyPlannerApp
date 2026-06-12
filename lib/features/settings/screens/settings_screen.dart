import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/surface_3d.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.5),
                              ),
                              child: const Icon(Iconsax.setting_2,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Settings',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Customize your experience',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                child: const Icon(Iconsax.close_circle,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Appearance ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(
                            icon: Iconsax.paintbucket, label: 'Appearance'),
                        const SizedBox(height: 12),
                        Surface3D(
                          color: theme.colorScheme.surfaceContainerLow,
                          edgeColor:
                              AppTheme.dustyPink.withValues(alpha: 0.9),
                          borderColor: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                          depth: 6,
                          borderRadius: 20,
                          child: Column(
                            children: [
                              _ThemeOption(
                                icon: Iconsax.sun_1,
                                label: 'Light',
                                isSelected: themeMode == ThemeMode.light,
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setMode(ThemeMode.light),
                              ),
                              _Divider(),
                              _ThemeOption(
                                icon: Iconsax.moon,
                                label: 'Dark',
                                isSelected: themeMode == ThemeMode.dark,
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setMode(ThemeMode.dark),
                              ),
                              _Divider(),
                              _ThemeOption(
                                icon: Iconsax.mobile,
                                label: 'System Default',
                                isSelected: themeMode == ThemeMode.system,
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setMode(ThemeMode.system),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── About ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(
                            icon: Iconsax.info_circle, label: 'About'),
                        const SizedBox(height: 12),
                        Surface3D(
                          color: theme.colorScheme.surfaceContainerLow,
                          edgeColor:
                              AppTheme.dustyPink.withValues(alpha: 0.9),
                          borderColor: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                          depth: 6,
                          borderRadius: 20,
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Iconsax.calendar_1,
                                label: 'App Name',
                                value: 'Daily Planner',
                              ),
                              _Divider(),
                              _InfoRow(
                                icon: Iconsax.code,
                                label: 'Version',
                                value: '1.0.0',
                              ),
                              _Divider(),
                              _InfoRow(
                                icon: Iconsax.cloud,
                                label: 'Sync',
                                value: 'Appwrite (Offline-first)',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.mauve,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: AppTheme.mauve),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.mauve,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppTheme.deepPlum
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.deepPlum,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 52,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
