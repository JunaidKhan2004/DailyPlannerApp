import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as aw;

import '../../features/tasks/data/models/task_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FILL THESE IN — Appwrite Console → your project
// ─────────────────────────────────────────────────────────────────────────────
class AppwriteConfig {
  /// Console → Settings → Project ID
  static const String projectId = '6a2b18ea0007d777d101';

  /// Console → Databases → your database → Database ID
  static const String databaseId = '6a2b1cf0001aeeee9735';

  /// Console → Databases → your database → tasks collection → Collection ID
  static const String tasksCollectionId = 'task_id';

  /// Appwrite Cloud endpoint (keep as-is for cloud.appwrite.io)
  static const String endpoint = 'https://nyc.cloud.appwrite.io/v1';
}
// ─────────────────────────────────────────────────────────────────────────────

/// Offline-first cloud sync via Appwrite.
/// All methods fail silently so Hive remains the source of truth.
class AppwriteService {
  AppwriteService._();

  static late final Client _client;
  static late final Account _account;
  static late final Databases _databases;

  static bool _ready = false;

  static Future<void> init() async {
    if (_isPlaceholder) return;

    _client = Client()
      ..setEndpoint(AppwriteConfig.endpoint)
      ..setProject(AppwriteConfig.projectId);

    _account = Account(_client);
    _databases = Databases(_client);

    await _ensureSession();
    _ready = true;
  }

  /// Creates an anonymous session so documents are scoped to this device.
  static Future<void> _ensureSession() async {
    try {
      await _account.get();
    } on AppwriteException {
      try {
        await _account.createAnonymousSession();
      } catch (_) {}
    }
  }

  static Future<String?> get _userId async {
    try {
      final user = await _account.get();
      return user.$id;
    } catch (_) {
      return null;
    }
  }

  /// Upsert (create or update) a task document in Appwrite.
  static Future<void> upsertTask(TaskModel task) async {
    if (!_ready) return;
    final uid = await _userId;
    if (uid == null) return;

    final data = {
      'title': task.title,
      'description': task.description,
      'due_date': task.dueDate.toIso8601String(),
      'due_time_minutes': task.dueTimeMinutes,
      'priority': task.priority.name,
      'is_completed': task.isCompleted,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
      'user_id': uid,
    };

    try {
      // Try to update first; if not found, create.
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: task.id,
        data: data,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        try {
          await _databases.createDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.tasksCollectionId,
            documentId: task.id,
            data: data,
            permissions: [
              Permission.read(Role.user(uid)),
              Permission.update(Role.user(uid)),
              Permission.delete(Role.user(uid)),
            ],
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Delete a task document from Appwrite.
  static Future<void> deleteTask(String taskId) async {
    if (!_ready) return;
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        documentId: taskId,
      );
    } catch (_) {}
  }

  /// Fetch all tasks for the current user (for initial sync).
  static Future<List<TaskModel>> fetchAll() async {
    if (!_ready) return [];
    final uid = await _userId;
    if (uid == null) return [];

    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.tasksCollectionId,
        queries: [Query.equal('user_id', uid)],
      );
      return result.documents.map(_docToTask).toList();
    } catch (_) {
      return [];
    }
  }

  static TaskModel _docToTask(aw.Document doc) {
    final d = doc.data;
    return TaskModel(
      id: doc.$id,
      title: d['title'] as String,
      description: (d['description'] as String?) ?? '',
      dueDate: DateTime.parse(d['due_date'] as String),
      dueTimeMinutes: d['due_time_minutes'] as int?,
      priority: TaskPriority.values.byName(d['priority'] as String),
      isCompleted: d['is_completed'] as bool,
      createdAt: DateTime.parse(d['created_at'] as String),
      updatedAt: DateTime.parse(d['updated_at'] as String),
      isSynced: true,
    );
  }

  static bool get _isPlaceholder =>
      AppwriteConfig.projectId == 'YOUR_PROJECT_ID';
}
