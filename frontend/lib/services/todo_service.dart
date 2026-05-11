import 'package:drift/drift.dart';
import 'package:frontend/database/database.dart';
import 'package:uuid/uuid.dart';

class TodoService {
  TodoService(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

// filters the delete todo from the list returning only the todos that are not deleted
  Stream<List<TodoTableData>> watchTodos() {
    return (_db.select(_db.todoTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<TodoTableData>> getTodos() {
    return (_db.select(_db.todoTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<String> addTodo(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Todo title cannot be empty.');
    }

    final id = _uuid.v4();
    return _db
        .into(_db.todoTable)
        .insert(
          TodoTableCompanion.insert(
            id: id,
            title: trimmedTitle,
            version: const Value(1),
          ),
        )
        .then((_) => id);
  }

  Future<int> updateTodoTitle({required String id, required String title}) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Todo title cannot be empty.');
    }

    return _bumpVersionAndWrite(
      id,
      TodoTableCompanion(
        title: Value(trimmedTitle),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<int> deleteTodo(String id) {
    return _bumpVersionAndWrite(
      id,
      TodoTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Increments [version] on every mutation so pull-side merge can prefer
  /// strictly newer revisions over wall-clock [updatedAt] alone.
  Future<int> _bumpVersionAndWrite(String id, TodoTableCompanion changes) async {
    final row = await (_db.select(_db.todoTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return 0;

    return (_db.update(_db.todoTable)..where((t) => t.id.equals(id))).write(
      changes.copyWith(version: Value(row.version + 1)),
    );
  }

  Future<int> deleteAllTodos() {
    return _db.delete(_db.todoTable).go();
  }
}
