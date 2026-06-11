import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/animated_background.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/surface_3d.dart';
import '../../data/models/task_model.dart';
import '../providers/task_providers.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  const AddEditTaskScreen({super.key, this.task, this.initialDate});

  final TaskModel? task;
  final DateTime? initialDate;

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _dueDate;
  TimeOfDay? _dueTime;
  late TaskPriority _priority;

  late final AnimationController _entryCtrl;

  bool get _isEditing => widget.task != null;

  // Staggered entry intervals
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _field1Fade;
  late final Animation<Offset> _field1Slide;
  late final Animation<double> _field2Fade;
  late final Animation<Offset> _field2Slide;
  late final Animation<double> _field3Fade;
  late final Animation<Offset> _field3Slide;
  late final Animation<double> _btnFade;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate ??
        widget.initialDate ??
        AppDateUtils.dateOnly(DateTime.now());
    _dueTime = task?.dueTimeMinutes != null
        ? TimeOfDay(
            hour: task!.dueTimeMinutes! ~/ 60,
            minute: task.dueTimeMinutes! % 60)
        : null;
    _priority = task?.priority ?? TaskPriority.medium;

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    Animation<double> _fade(double s, double e) => CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        );
    Animation<Offset> _slide(double s, double e) =>
        Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(s, e, curve: Curves.easeOutCubic)),
        );

    _headerFade = _fade(0.0, 0.4);
    _headerSlide = _slide(0.0, 0.45);
    _field1Fade = _fade(0.12, 0.52);
    _field1Slide = _slide(0.12, 0.52);
    _field2Fade = _fade(0.24, 0.62);
    _field2Slide = _slide(0.24, 0.62);
    _field3Fade = _fade(0.36, 0.72);
    _field3Slide = _slide(0.36, 0.72);
    _btnFade = _fade(0.52, 0.88);
    _btnSlide = _slide(0.52, 0.88);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dueDate = AppDateUtils.dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(taskRepositoryProvider);
    final timeMinutes =
        _dueTime != null ? _dueTime!.hour * 60 + _dueTime!.minute : null;
    if (_isEditing) {
      await repo.updateTask(widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        dueTimeMinutes: () => timeMinutes,
        priority: _priority,
      ));
    } else {
      final now = DateTime.now();
      await repo.addTask(TaskModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        dueTimeMinutes: timeMinutes,
        priority: _priority,
        createdAt: now,
        updatedAt: now,
      ));
    }
    if (mounted) context.pop();
  }

  Widget _animated({
    required Animation<double> fade,
    required Animation<Offset> slide,
    required Widget child,
  }) =>
      FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  // ── Gradient header ──
                  SliverToBoxAdapter(
                    child: _animated(
                      fade: _headerFade,
                      slide: _headerSlide,
                      child: _TaskHeader(
                        isEditing: _isEditing,
                        priority: _priority,
                        onClose: () => context.pop(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Title + Description ──
                  SliverToBoxAdapter(
                    child: _animated(
                      fade: _field1Fade,
                      slide: _field1Slide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Surface3D(
                          color: theme.colorScheme.surfaceContainerLow,
                          edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
                          borderColor: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                          depth: 6,
                          borderRadius: 24,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                            child: Column(
                              children: [
                                _FieldRow(
                                  icon: Iconsax.edit_2,
                                  child: TextFormField(
                                    controller: _titleController,
                                    autofocus: !_isEditing,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Task title...',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Title is required'
                                            : null,
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                                _FieldRow(
                                  icon: Iconsax.note_text,
                                  iconPadding:
                                      const EdgeInsets.only(bottom: 52),
                                  child: TextFormField(
                                    controller: _descriptionController,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    maxLines: 4,
                                    style: theme.textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: 'Add a note (optional)...',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── Schedule ──
                  SliverToBoxAdapter(
                    child: _animated(
                      fade: _field2Fade,
                      slide: _field2Slide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionChip(
                              icon: Iconsax.calendar_1,
                              label: 'Schedule',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _PickerTile(
                                    icon: Iconsax.calendar_1,
                                    label: AppDateUtils.formatShortDate(_dueDate),
                                    sublabel: DateFormat('EEEE').format(_dueDate),
                                    onTap: _pickDate,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PickerTile(
                                    icon: Iconsax.clock,
                                    label: _dueTime != null
                                        ? _dueTime!.format(context)
                                        : 'No time',
                                    sublabel: _dueTime != null ? 'Tap to change' : 'Optional',
                                    isPlaceholder: _dueTime == null,
                                    onTap: _pickTime,
                                    onClear: _dueTime != null
                                        ? () => setState(() => _dueTime = null)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // ── Priority ──
                  SliverToBoxAdapter(
                    child: _animated(
                      fade: _field3Fade,
                      slide: _field3Slide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionChip(
                              icon: Iconsax.flash_1,
                              label: 'Priority',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (final p in TaskPriority.values) ...[
                                  Expanded(
                                    child: _PriorityOption(
                                      priority: p,
                                      isSelected: _priority == p,
                                      onTap: () =>
                                          setState(() => _priority = p),
                                    ),
                                  ),
                                  if (p != TaskPriority.values.last)
                                    const SizedBox(width: 10),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // ── Save button ──
                  SliverToBoxAdapter(
                    child: _animated(
                      fade: _btnFade,
                      slide: _btnSlide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Surface3D(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.gradientStart,
                              AppTheme.gradientEnd,
                            ],
                          ),
                          edgeColor: Surface3D.darken(AppTheme.deepPlum, 0.4),
                          depth: 7,
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          onTap: _save,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.tick_circle,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                _isEditing ? 'Save Changes' : 'Create Task',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Delete button ──
                  if (_isEditing) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: _animated(
                        fade: _btnFade,
                        slide: _btnSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Surface3D(
                            color: theme.colorScheme.errorContainer
                                .withValues(alpha: 0.6),
                            edgeColor: theme.colorScheme.error
                                .withValues(alpha: 0.5),
                            borderColor: theme.colorScheme.error
                                .withValues(alpha: 0.3),
                            depth: 5,
                            borderRadius: 20,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onTap: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                title: 'Delete Task?',
                                message:
                                    'Are you sure you want to delete "${widget.task!.title}"? This cannot be undone.',
                              );
                              if (!confirmed) return;
                              await ref
                                  .read(taskRepositoryProvider)
                                  .deleteTask(widget.task!.id);
                              if (context.mounted) context.pop();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.trash,
                                    color: theme.colorScheme.error, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete Task',
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task header ───────────────────────────────────────────────────────────────

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({
    required this.isEditing,
    required this.priority,
    required this.onClose,
  });

  final bool isEditing;
  final TaskPriority priority;
  final VoidCallback onClose;

  Color get _priorityColor => switch (priority) {
        TaskPriority.high => AppTheme.priorityHigh,
        TaskPriority.medium => AppTheme.priorityMedium,
        TaskPriority.low => AppTheme.priorityLow,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
              // Icon bubble
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isEditing ? Iconsax.edit_2 : Iconsax.add_circle,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Task' : 'New Task',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Update your task details'
                          : 'What do you want to accomplish?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Iconsax.close_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section chip label ────────────────────────────────────────────────────────

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.icon, required this.label});
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

// ── Field row (icon + input) ──────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.child,
    this.iconPadding,
  });
  final IconData icon;
  final Widget child;
  final EdgeInsets? iconPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: iconPadding ?? const EdgeInsets.only(top: 16),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.mauve.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

// ── Picker tile ───────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.onClear,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Surface3D(
      color: theme.colorScheme.surfaceContainerLow,
      edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
      borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      depth: 5,
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.mauve.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 17, color: AppTheme.mauve),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPlaceholder
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  sublabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Icon(Iconsax.close_circle,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ── Priority option ───────────────────────────────────────────────────────────

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color => switch (priority) {
        TaskPriority.high => AppTheme.priorityHigh,
        TaskPriority.medium => AppTheme.priorityMedium,
        TaskPriority.low => AppTheme.priorityLow,
      };

  String get _label => switch (priority) {
        TaskPriority.high => 'High',
        TaskPriority.medium => 'Med',
        TaskPriority.low => 'Low',
      };

  IconData get _icon => switch (priority) {
        TaskPriority.high => Iconsax.flash_1,
        TaskPriority.medium => Iconsax.star_1,
        TaskPriority.low => Iconsax.coffee,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unsel = theme.colorScheme.onSurfaceVariant;
    return Surface3D(
      color: isSelected ? _color : theme.colorScheme.surfaceContainerLow,
      edgeColor: isSelected
          ? Surface3D.darken(_color, 0.35)
          : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
      borderColor: isSelected
          ? Surface3D.darken(_color, 0.2)
          : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      depth: isSelected ? 6 : 4,
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHigh,
            ),
            child: Icon(
              _icon,
              size: 20,
              color: isSelected ? Colors.white : unsel,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : unsel,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
