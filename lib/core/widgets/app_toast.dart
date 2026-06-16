import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../app/theme/app_theme.dart';
import 'surface_3d.dart';

enum ToastType { info, success, error, warning }

abstract class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    IconData? icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        type: type,
        icon: icon,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success, icon: Iconsax.tick_circle);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error, icon: Iconsax.close_circle);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning, icon: Iconsax.warning_2);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info, icon: Iconsax.info_circle);

}

// Overlay wrapper handles entry/exit animation + auto-dismiss
class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.onDismissed,
    this.icon,
  });

  final String message;
  final ToastType type;
  final IconData? icon;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();

    // Auto-dismiss after 3 s
    Future.delayed(const Duration(milliseconds: 3000), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: _dismiss,
              child: _ToastCard(
                message: widget.message,
                type: widget.type,
                icon: widget.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.message,
    required this.type,
    this.icon,
  });

  final String message;
  final ToastType type;
  final IconData? icon;

  Color get _color => switch (type) {
        ToastType.success => AppTheme.priorityLow,          // green
        ToastType.error   => AppTheme.priorityHigh,          // red
        ToastType.warning => AppTheme.priorityMedium,        // orange
        ToastType.info    => AppTheme.mauve,                 // mauve
      };

  Color get _bgColor => switch (type) {
        ToastType.success => const Color(0xFF1E3A1E),
        ToastType.error   => const Color(0xFF3A1E1E),
        ToastType.warning => const Color(0xFF3A2E1A),
        ToastType.info    => const Color(0xFF2A2230),
      };

  IconData get _defaultIcon => switch (type) {
        ToastType.success => Iconsax.tick_circle,
        ToastType.error   => Iconsax.close_circle,
        ToastType.warning => Iconsax.warning_2,
        ToastType.info    => Iconsax.info_circle,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedIcon = icon ?? _defaultIcon;
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? _bgColor
        : Color.lerp(Colors.white, _color, 0.08)!;

    return Surface3D(
      color: cardColor,
      edgeColor: Surface3D.darken(_color, 0.3),
      borderColor: _color.withValues(alpha: 0.35),
      depth: 5,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.15),
            ),
            child: Icon(usedIcon, size: 20, color: _color),
          ),
          const SizedBox(width: 14),
          // Message
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.92)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Dismiss hint
          Icon(
            Iconsax.close_circle,
            size: 16,
            color: _color.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

