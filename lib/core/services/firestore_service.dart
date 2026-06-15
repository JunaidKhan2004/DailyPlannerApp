import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../features/tasks/data/models/task_model.dart';

/// Offline-first cloud sync via Firebase Firestore.
/// All methods fail silently — Hive remains the source of truth.
///
/// Collection path: users/{uid}/tasks/{taskId}
class FirestoreService {
  FirestoreService._();

  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>>? get _tasksCol {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('tasks');
  }

  /// Upsert (create or update) a task document in Firestore.
  static Future<void> upsertTask(TaskModel task) async {
    final col = _tasksCol;
    if (col == null) return;
    try {
      await col.doc(task.id).set(_toMap(task), SetOptions(merge: true));
    } catch (_) {}
  }

  /// Delete a task document from Firestore.
  static Future<void> deleteTask(String taskId) async {
    final col = _tasksCol;
    if (col == null) return;
    try {
      await col.doc(taskId).delete();
    } catch (_) {}
  }

  /// Fetch all tasks for the current user (initial sync on login).
  static Future<List<TaskModel>> fetchAll() async {
    final col = _tasksCol;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((d) => _fromMap(d.id, d.data())).toList();
    } catch (_) {
      return [];
    }
  }

  /// Full two-way sync called on login:
  /// 1. Upload local Hive tasks that Firestore doesn't have (or are newer).
  /// 2. Download Firestore tasks that Hive doesn't have (or are newer).
  /// Strategy: last-write-wins based on updatedAt.
  static Future<void> syncOnLogin() async {
    final col = _tasksCol;
    if (col == null) return;

    final box = Hive.box<TaskModel>(AppConstants.tasksBox);

    try {
      // ── Step 1: fetch cloud tasks ──────────────────────────────────────────
      final snapshot = await col.get();
      final cloudTasks = {
        for (final d in snapshot.docs) d.id: _fromMap(d.id, d.data()),
      };

      // ── Step 2: merge cloud → Hive (download newer cloud tasks) ───────────
      for (final cloudTask in cloudTasks.values) {
        final localTask = box.get(cloudTask.id);
        if (localTask == null ||
            cloudTask.updatedAt.isAfter(localTask.updatedAt)) {
          await box.put(cloudTask.id, cloudTask);
        }
      }

      // ── Step 3: merge Hive → cloud (upload newer local tasks) ─────────────
      final localTasks = box.values.toList();
      for (final localTask in localTasks) {
        final cloudTask = cloudTasks[localTask.id];
        if (cloudTask == null ||
            localTask.updatedAt.isAfter(cloudTask.updatedAt)) {
          await col
              .doc(localTask.id)
              .set(_toMap(localTask), SetOptions(merge: true));
        }
      }
    } catch (_) {}
  }

  static Map<String, dynamic> _toMap(TaskModel task) => {
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate.toIso8601String(),
        'due_time_minutes': task.dueTimeMinutes,
        'priority': task.priority.name,
        'category': task.category.name,
        'is_completed': task.isCompleted,
        'is_synced': true,
        'subtasks': task.subtasks
            .map((s) => {'id': s.id, 'title': s.title, 'is_done': s.isDone})
            .toList(),
        'created_at': task.createdAt.toIso8601String(),
        'updated_at': task.updatedAt.toIso8601String(),
      };

  static TaskModel _fromMap(String id, Map<String, dynamic> d) {
    final rawSubtasks = d['subtasks'] as List<dynamic>? ?? [];
    return TaskModel(
      id: id,
      title: d['title'] as String,
      description: (d['description'] as String?) ?? '',
      dueDate: DateTime.parse(d['due_date'] as String),
      dueTimeMinutes: d['due_time_minutes'] as int?,
      priority: TaskPriority.values.byName(d['priority'] as String? ?? 'low'),
      category:
          TaskCategory.values.byName(d['category'] as String? ?? 'other'),
      isCompleted: d['is_completed'] as bool? ?? false,
      isSynced: true,
      subtasks: rawSubtasks
          .map((s) => SubTask(
                id: s['id'] as String,
                title: s['title'] as String,
                isDone: s['is_done'] as bool? ?? false,
              ))
          .toList(),
      createdAt: DateTime.parse(d['created_at'] as String),
      updatedAt: DateTime.parse(d['updated_at'] as String),
    );
  }
}
