import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/animated_background.dart';
import '../../../../core/widgets/surface_3d.dart';
import '../../data/models/task_model.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  TaskPriority? _filterPriority;
  bool? _filterCompleted;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TaskModel> _filtered(List<TaskModel> all) {
    var list = all.where((t) {
      final q = _query.trim().toLowerCase();
      if (q.isNotEmpty) {
        if (!t.title.toLowerCase().contains(q) &&
            !t.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterPriority != null && t.priority != _filterPriority) return false;
      if (_filterCompleted != null && t.isCompleted != _filterCompleted) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTasks = ref.watch(tasksStreamProvider).valueOrNull ?? [];
    final results = _filtered(allTasks);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
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
                            child: const Icon(Iconsax.search_normal,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Search Tasks',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${allTasks.length} total tasks',
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

                const SizedBox(height: 14),

                // ── Search bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Surface3D(
                    color: theme.colorScheme.surfaceContainerLow,
                    edgeColor: AppTheme.dustyPink.withValues(alpha: 0.9),
                    borderColor:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    depth: 5,
                    borderRadius: 18,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Iconsax.search_normal,
                            size: 20,
                            color: AppTheme.mauve.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (v) => setState(() => _query = v),
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Search by title or note...',
                              hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            child: Icon(Iconsax.close_circle,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Filter chips ──
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected:
                            _filterPriority == null && _filterCompleted == null,
                        onTap: () => setState(() {
                          _filterPriority = null;
                          _filterCompleted = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        icon: Iconsax.clock,
                        isSelected: _filterCompleted == false,
                        onTap: () => setState(() {
                          _filterCompleted =
                              _filterCompleted == false ? null : false;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Done',
                        icon: Iconsax.tick_circle,
                        isSelected: _filterCompleted == true,
                        onTap: () => setState(() {
                          _filterCompleted =
                              _filterCompleted == true ? null : true;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'High',
                        icon: Iconsax.flash_1,
                        color: AppTheme.priorityHigh,
                        isSelected: _filterPriority == TaskPriority.high,
                        onTap: () => setState(() {
                          _filterPriority = _filterPriority == TaskPriority.high
                              ? null
                              : TaskPriority.high;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Medium',
                        icon: Iconsax.star_1,
                        color: AppTheme.priorityMedium,
                        isSelected: _filterPriority == TaskPriority.medium,
                        onTap: () => setState(() {
                          _filterPriority =
                              _filterPriority == TaskPriority.medium
                                  ? null
                                  : TaskPriority.medium;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Low',
                        icon: Iconsax.coffee,
                        color: AppTheme.priorityLow,
                        isSelected: _filterPriority == TaskPriority.low,
                        onTap: () => setState(() {
                          _filterPriority = _filterPriority == TaskPriority.low
                              ? null
                              : TaskPriority.low;
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Results count ──
                if (_query.isNotEmpty || _filterPriority != null || _filterCompleted != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                    child: Row(
                      children: [
                        Text(
                          '${results.length} result${results.length == 1 ? '' : 's'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.mauve,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Results list ──
                Expanded(
                  child: results.isEmpty
                      ? _EmptySearch(hasQuery: _query.isNotEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: results.length,
                          itemBuilder: (_, i) => TaskCard(task: results[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? AppTheme.deepPlum;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.6)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Surface3D(
            color: AppTheme.dustyPink.withValues(alpha: 0.5),
            edgeColor: Surface3D.darken(AppTheme.dustyPink, 0.3),
            depth: 3,
            borderRadius: 28,
            padding: const EdgeInsets.all(22),
            child: Icon(
              hasQuery ? Iconsax.search_normal : Iconsax.note_2,
              size: 30,
              color: Surface3D.darken(AppTheme.deepPlum, 0.1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No tasks found' : 'Search your tasks',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            hasQuery
                ? 'Try a different keyword or filter'
                : 'Type above to find tasks by title or note',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
