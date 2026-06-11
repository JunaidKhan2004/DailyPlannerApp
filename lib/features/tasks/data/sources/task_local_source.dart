import 'package:hive_ce/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/task_model.dart';

/// Hive-backed local data source. The single source of truth for the UI.
class TaskLocalSource {
  Box<TaskModel> get _box => Hive.box<TaskModel>(AppConstants.tasksBox);

  /// Emits the full task list immediately and on every change.
  Stream<List<TaskModel>> watchAll() async* {
    yield _box.values.toList();
    yield* _box.watch().map((_) => _box.values.toList());
  }

  List<TaskModel> getAll() => _box.values.toList();

  TaskModel? getById(String id) => _box.get(id);

  Future<void> upsert(TaskModel task) => _box.put(task.id, task);

  Future<void> delete(String id) => _box.delete(id);
}
