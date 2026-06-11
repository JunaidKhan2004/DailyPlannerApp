import '../../data/models/task_model.dart';

/// Contract for task storage. The offline-first implementation writes to
/// Hive immediately; a Supabase-backed sync layer plugs in behind this
/// interface later without touching the UI.
abstract class TaskRepository {
  Stream<List<TaskModel>> watchTasks();

  Future<void> addTask(TaskModel task);

  Future<void> updateTask(TaskModel task);

  Future<void> deleteTask(String id);

  Future<void> toggleCompleted(String id);
}
