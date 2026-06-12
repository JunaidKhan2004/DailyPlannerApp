import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/surface_3d.dart';
import '../../settings/providers/settings_providers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Iconsax.calendar_2,
      title: 'Plan Your Day',
      subtitle:
          'Organize your tasks by date. Switch between week and month view to see your whole schedule at a glance.',
      gradient: [AppTheme.deepPlum, AppTheme.mauve],
    ),
    _OnboardingPage(
      icon: Iconsax.tick_circle,
      title: 'Track Your Progress',
      subtitle:
          'Set priorities, add reminders, and mark tasks complete. Watch your progress ring fill up as you get things done.',
      gradient: [Color(0xFF7E5F8E), AppTheme.dustyPink],
    ),
    _OnboardingPage(
      icon: Iconsax.cloud,
      title: 'Synced Everywhere',
      subtitle:
          'Your tasks are saved offline instantly and synced to the cloud automatically when you\'re connected.',
      gradient: [AppTheme.mauve, AppTheme.peach],
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingComplete();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                  ),
                ),

                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _currentPage
                            ? AppTheme.deepPlum
                            : AppTheme.dustyPink.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // CTA button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Surface3D(
                    gradient: LinearGradient(
                      colors: _pages[_currentPage].gradient,
                    ),
                    edgeColor: Surface3D.darken(AppTheme.deepPlum, 0.4),
                    depth: 7,
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    onTap: _next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Get Started' : 'Next',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isLast
                              ? Iconsax.arrow_right_3
                              : Iconsax.arrow_right_3,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Surface3D(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: page.gradient,
            ),
            edgeColor: Surface3D.darken(page.gradient.first, 0.35),
            depth: 8,
            borderRadius: 36,
            padding: const EdgeInsets.all(36),
            child: Icon(page.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
