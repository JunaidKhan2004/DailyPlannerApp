import 'package:hive_ce/hive.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory {
  personal,
  work,
  health,
  study,
  other;

  String get label => switch (this) {
        TaskCategory.personal => 'Personal',
        TaskCategory.work     => 'Work',
        TaskCategory.health   => 'Health',
        TaskCategory.study    => 'Study',
        TaskCategory.other    => 'Other',
      };

  String get shortLabel => switch (this) {
        TaskCategory.personal => 'Home',
        TaskCategory.work     => 'Work',
        TaskCategory.health   => 'Health',
        TaskCategory.study    => 'Study',
        TaskCategory.other    => 'Other',
      };

  // kept for Firestore/search display
  String get emoji => switch (this) {
        TaskCategory.personal => '🏠',
        TaskCategory.work     => '💼',
        TaskCategory.health   => '💪',
        TaskCategory.study    => '📚',
        TaskCategory.other    => '📌',
      };

  dynamic get icon => switch (this) {
        TaskCategory.personal => Iconsax.home_2,
        TaskCategory.work     => Iconsax.briefcase,
        TaskCategory.health   => Iconsax.heart,
        TaskCategory.study    => Iconsax.book_1,
        TaskCategory.other    => Iconsax.category_2,
      };
}

class SubTask {
  SubTask({required this.id, required this.title, this.isDone = false});

  final String id;
  String title;
  bool isDone;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory SubTask.fromMap(Map m) => SubTask(
        id: m['id'] as String,
        title: m['title'] as String,
        isDone: m['isDone'] as bool? ?? false,
      );
}

class TaskModel extends HiveObject {
  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.dueTimeMinutes,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    List<SubTask>? subtasks,
  }) : subtasks = subtasks ?? [];

  final String id;
  String title;
  String description;

  /// Date-only (time component zeroed out).
  DateTime dueDate;

  /// Optional time of day stored as minutes since midnight.
  int? dueTimeMinutes;

  TaskPriority priority;
  TaskCategory category;
  bool isCompleted;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  List<SubTask> subtasks;

  int get subtasksDone => subtasks.where((s) => s.isDone).length;

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    int? Function()? dueTimeMinutes,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? updatedAt,
    bool? isSynced,
    List<SubTask>? subtasks,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTimeMinutes:
          dueTimeMinutes != null ? dueTimeMinutes() : this.dueTimeMinutes,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'due_time_minutes': dueTimeMinutes,
        'priority': priority.name,
        'category': category.name,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        dueDate: DateTime.parse(json['due_date'] as String),
        dueTimeMinutes: json['due_time_minutes'] as int?,
        priority: TaskPriority.values.byName(json['priority'] as String),
        category: json['category'] != null
            ? TaskCategory.values.byName(json['category'] as String)
            : TaskCategory.personal,
        isCompleted: json['is_completed'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isSynced: true,
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((e) => SubTask.fromMap(e as Map))
                .toList() ??
            [],
      );
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final fields = reader.readMap().cast<String, dynamic>();
    return TaskModel(
      id: fields['id'] as String,
      title: fields['title'] as String,
      description: fields['description'] as String,
      dueDate: fields['dueDate'] as DateTime,
      dueTimeMinutes: fields['dueTimeMinutes'] as int?,
      priority: TaskPriority.values[fields['priority'] as int],
      category: fields['category'] != null
          ? TaskCategory.values[fields['category'] as int]
          : TaskCategory.personal,
      isCompleted: fields['isCompleted'] as bool,
      createdAt: fields['createdAt'] as DateTime,
      updatedAt: fields['updatedAt'] as DateTime,
      isSynced: fields['isSynced'] as bool,
      subtasks: (fields['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromMap(e as Map))
              .toList() ??
          [],
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer.writeMap({
      'id': obj.id,
      'title': obj.title,
      'description': obj.description,
      'dueDate': obj.dueDate,
      'dueTimeMinutes': obj.dueTimeMinutes,
      'priority': obj.priority.index,
      'category': obj.category.index,
      'isCompleted': obj.isCompleted,
      'createdAt': obj.createdAt,
      'updatedAt': obj.updatedAt,
      'isSynced': obj.isSynced,
      'subtasks': obj.subtasks.map((s) => s.toMap()).toList(),
    });
  }
}
