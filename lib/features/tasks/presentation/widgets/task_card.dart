import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/surface_3d.dart';
import '../../data/models/task_model.dart';
import '../providers/task_providers.dart';

class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({super.key, required this.task});

  final TaskModel task;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
    if (widget.task.isCompleted) _checkCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(TaskCard old) {
    super.didUpdateWidget(old);
    if (widget.task.isCompleted && !old.task.isCompleted) {
      _checkCtrl.forward(from: 0);
    } else if (!widget.task.isCompleted && old.task.isCompleted) {
      _checkCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  TaskModel get task => widget.task;

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.read(taskRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Slidable(
        key: ValueKey(task.id),
        // ── Swipe right → toggle complete ────────────────────────────────────
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.18,
          children: [
            CustomSlidableAction(
              onPressed: (_) async {
                HapticFeedback.mediumImpact();
                await repo.toggleCompleted(task.id);
                if (context.mounted) {
                  AppToast.success(
                    context,
                    task.isCompleted ? 'Marked as pending' : 'Task completed!',
                  );
                }
              },
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppTheme.priorityLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  task.isCompleted ? Iconsax.refresh : Iconsax.tick_circle,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        // ── Swipe left → delete ───────────────────────────────────────────────
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.18,
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
                  AppToast.success(context, 'Task deleted');
                }
              },
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: AppTheme.priorityHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Iconsax.trash, size: 22, color: Colors.white),
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
                        onTap: () {
                          HapticFeedback.lightImpact();
                          repo.toggleCompleted(task.id);
                        },
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
                              ? ScaleTransition(
                                  scale: _checkScale,
                                  child: const Icon(Icons.check_rounded,
                                      size: 17, color: Colors.white),
                                )
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
                                  icon: task.category.icon as IconData,
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
