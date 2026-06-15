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

  bool get _isOverdue {
    if (task.isCompleted) return false;
    final today = AppDateUtils.dateOnly(DateTime.now());
    if (task.dueDate.isBefore(today)) return true;
    if (AppDateUtils.isSameDay(task.dueDate, DateTime.now()) &&
        task.dueTimeMinutes != null) {
      final nowMinutes = DateTime.now().hour * 60 + DateTime.now().minute;
      return task.dueTimeMinutes! < nowMinutes;
    }
    return false;
  }

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
        TaskPriority.medium => 'Med',
        TaskPriority.low => 'Low',
      };

  Color get _categoryColor => switch (task.category) {
        TaskCategory.personal => AppTheme.mauve,
        TaskCategory.work => const Color(0xFF5B8DEF),
        TaskCategory.health => const Color(0xFF4CAF50),
        TaskCategory.study => const Color(0xFFFF9800),
        TaskCategory.other => const Color(0xFF9E9E9E),
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
          motion: const StretchMotion(),
          extentRatio: 0.22,
          children: [
            CustomSlidableAction(
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
                    SnackBar(
                      content: const Text('Task deleted'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              backgroundColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onError,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE57373),
                      theme.colorScheme.error,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.trash, size: 22, color: Colors.white),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: task.isCompleted ? 0.65 : 1,
          child: Surface3D(
            color: theme.colorScheme.surfaceContainerLow,
            edgeColor: _isOverdue
                ? AppTheme.priorityHigh.withValues(alpha: 0.9)
                : _priorityColor.withValues(alpha: 0.75),
            borderColor: _isOverdue
                ? AppTheme.priorityHigh.withValues(alpha: 0.35)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                            // Chips row
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _Chip(
                                  label: task.category.label,
                                  color: _categoryColor,
                                  icon: null,
                                  emoji: task.category.emoji,
                                ),
                                _Chip(
                                  label: _priorityLabel,
                                  color: _priorityColor,
                                  icon: _priorityIcon,
                                ),
                                if (task.dueTimeMinutes != null)
                                  _Chip(
                                    label: AppDateUtils.formatTimeFromMinutes(
                                        task.dueTimeMinutes!),
                                    color: theme.colorScheme.primary,
                                    icon: Iconsax.clock,
                                  ),
                                if (_isOverdue)
                                  _Chip(
                                    label: 'Overdue',
                                    color: AppTheme.priorityHigh,
                                    icon: Iconsax.warning_2,
                                  ),
                              ],
                            ),
                            // Subtask progress bar
                            if (task.subtasks.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: task.subtasks.isEmpty
                                            ? 0
                                            : task.subtasksDone /
                                                task.subtasks.length,
                                        minHeight: 4,
                                        backgroundColor: theme
                                            .colorScheme.outlineVariant
                                            .withValues(alpha: 0.3),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                _priorityColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${task.subtasksDone}/${task.subtasks.length}',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
  const _Chip({required this.label, required this.color, this.icon, this.emoji});

  final String label;
  final Color color;
  final IconData? icon;
  final String? emoji;

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
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
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
