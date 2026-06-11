import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../app/theme/app_theme.dart';
import 'surface_3d.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  IconData icon = Iconsax.trash,
  Color? confirmColor,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, anim, __, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.78, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
    pageBuilder: (context, _, __) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      confirmColor: confirmColor,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    this.confirmColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final Color? confirmColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = confirmColor ?? const Color(0xFFC06A6A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Surface3D(
            color: theme.colorScheme.surfaceContainerLow,
            edgeColor: Surface3D.darken(
                theme.colorScheme.surfaceContainerLow, 0.18),
            depth: 6,
            borderRadius: 28,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge
                  Surface3D(
                    color: danger.withValues(alpha: 0.15),
                    edgeColor: danger.withValues(alpha: 0.55),
                    depth: 4,
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Icon(icon, size: 32, color: danger),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Surface3D(
                          color: theme.colorScheme.surfaceContainerLow,
                          edgeColor: AppTheme.dustyPink.withValues(alpha: 0.8),
                          borderColor: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                          depth: 4,
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onTap: () => Navigator.of(context).pop(false),
                          child: Center(
                            child: Text(
                              cancelLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Surface3D(
                          color: danger,
                          edgeColor: Surface3D.darken(danger, 0.35),
                          depth: 4,
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onTap: () => Navigator.of(context).pop(true),
                          child: Center(
                            child: Text(
                              confirmLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
