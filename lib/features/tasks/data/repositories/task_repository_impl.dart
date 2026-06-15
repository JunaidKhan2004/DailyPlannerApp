import 'dart:async';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';
import '../sources/task_local_source.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local);

  final TaskLocalSource _local;

  @override
  Stream<List<TaskModel>> watchTasks() => _local.watchAll();

  @override
  Future<void> addTask(TaskModel task) async {
    await _local.upsert(task);
    await NotificationService.scheduleTaskReminder(task);
    unawaited(FirestoreService.upsertTask(task));
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final updated = task.copyWith(updatedAt: DateTime.now(), isSynced: false);
    await _local.upsert(updated);
    await NotificationService.cancelTaskReminder(task.id);
    await NotificationService.scheduleTaskReminder(updated);
    unawaited(FirestoreService.upsertTask(updated));
  }

  @override
  Future<void> deleteTask(String id) async {
    await _local.delete(id);
    await NotificationService.cancelTaskReminder(id);
    unawaited(FirestoreService.deleteTask(id));
  }

  @override
  Future<void> toggleCompleted(String id) async {
    final task = _local.getById(id);
    if (task == null) return;
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await _local.upsert(updated);
    if (updated.isCompleted) {
      await NotificationService.cancelTaskReminder(id);
    } else {
      await NotificationService.scheduleTaskReminder(updated);
    }
    unawaited(FirestoreService.upsertTask(updated));
  }
}
