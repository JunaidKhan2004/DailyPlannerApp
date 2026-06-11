import 'package:hive_ce/hive.dart';

enum TaskPriority { low, medium, high }

class TaskModel extends HiveObject {
  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.dueTimeMinutes,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  final String id;
  String title;
  String description;

  /// Date-only (time component zeroed out).
  DateTime dueDate;

  /// Optional time of day stored as minutes since midnight.
  int? dueTimeMinutes;

  TaskPriority priority;
  bool isCompleted;
  final DateTime createdAt;
  DateTime updatedAt;

  /// False while a change is pending upload to Supabase.
  bool isSynced;

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    int? Function()? dueTimeMinutes,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTimeMinutes:
          dueTimeMinutes != null ? dueTimeMinutes() : this.dueTimeMinutes,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? false,
    );
  }

  /// For Supabase sync (step 4).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'due_time_minutes': dueTimeMinutes,
        'priority': priority.name,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        dueDate: DateTime.parse(json['due_date'] as String),
        dueTimeMinutes: json['due_time_minutes'] as int?,
        priority: TaskPriority.values.byName(json['priority'] as String),
        isCompleted: json['is_completed'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        isSynced: true,
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
      isCompleted: fields['isCompleted'] as bool,
      createdAt: fields['createdAt'] as DateTime,
      updatedAt: fields['updatedAt'] as DateTime,
      isSynced: fields['isSynced'] as bool,
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
      'isCompleted': obj.isCompleted,
      'createdAt': obj.createdAt,
      'updatedAt': obj.updatedAt,
      'isSynced': obj.isSynced,
    });
  }
}
