import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/surface_3d.dart';
import '../../data/models/task_model.dart';
import '../providers/task_providers.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});

  final TaskModel task;

  Color get _priorityColor => switch (task.priority) {
        TaskPriority.high => AppTheme.priorityHigh,
        TaskPriority.medium => AppTheme.priorityMedium,
        TaskPriority.low => AppTheme.priorityLow,
      };

  IconData get _priorityIcon => switch (task.priority) {
        TaskPriority.high => Iconsax.flash_1,
        TaskPriority.medium => Iconsax.star_1,
        TaskPriority.low => Iconsax.coffee,
      };

  String get _priorityLabel => switch (task.priority) {
        TaskPriority.high => 'High',
        TaskPriority.medium => 'Medium',
        TaskPriority.low => 'Low',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(taskRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.24,
          children: [
            SlidableAction(
              onPressed: (_) async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Delete Task?',
                  message:
                      'Are you sure you want to delete "${task.title}"? This cannot be undone.',
                );
                if (!confirmed) return;
                await repo.deleteTask(task.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              icon: Iconsax.trash,
              label: 'Delete',
              borderRadius: BorderRadius.circular(18),
            ),
          ],
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: task.isCompleted ? 0.65 : 1,
          child: Surface3D(
            color: theme.colorScheme.surfaceContainerLow,
            edgeColor: _priorityColor.withValues(alpha: 0.75),
            borderColor:
                theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            depth: 5,
            borderRadius: 18,
            onTap: () => context.push(AppRoutes.editTask, extra: task),
            padding: const EdgeInsets.all(14),
            child: Row(
                    children: [
                      // Animated round checkbox
                      GestureDetector(
                        onTap: () => repo.toggleCompleted(task.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isCompleted
                                ? _priorityColor
                                : Colors.transparent,
                            border: Border.all(
                              color: _priorityColor,
                              width: 2,
                            ),
                          ),
                          child: task.isCompleted
                              ? const Icon(Icons.check_rounded,
                                  size: 17, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? theme.colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                task.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _Chip(
                                  label: _priorityLabel,
                                  color: _priorityColor,
                                  icon: _priorityIcon,
                                ),
                                if (task.dueTimeMinutes != null) ...[
                                  const SizedBox(width: 8),
                                  _Chip(
                                    label: AppDateUtils.formatTimeFromMinutes(
                                        task.dueTimeMinutes!),
                                    color: theme.colorScheme.primary,
                                    icon: Iconsax.clock,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 18,
                        color: theme.colorScheme.outlineVariant,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
