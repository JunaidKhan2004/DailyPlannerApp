import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';
import '../sources/task_local_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local);

  final TaskLocalSource _local;

  @override
  Stream<List<TaskModel>> watchTasks() => _local.watchAll();

  @override
  Future<void> addTask(TaskModel task) => _local.upsert(task);

  @override
  Future<void> updateTask(TaskModel task) =>
      _local.upsert(task.copyWith(updatedAt: DateTime.now()));

  @override
  Future<void> deleteTask(String id) => _local.delete(id);

  @override
  Future<void> toggleCompleted(String id) async {
    final task = _local.getById(id);
    if (task == null) return;
    await _local.upsert(task.copyWith(isCompleted: !task.isCompleted));
  }
}
