// Coordinates one full sync run for all entities.
import 'package:frontend/database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/sync/entities/syncable_entity.dart';
import 'package:frontend/sync/entities/todo_syncable.dart';
import 'package:frontend/sync/remote/todo_remote.dart';
import 'package:frontend/sync/remote_changes_batch.dart';

class SyncCoordinator {
  final AppDatabase db;
  final List<SyncableEntity> syncers;

  SyncCoordinator(this.db)
    : syncers = [
        TodoSyncable(db, const TodoRemote()),
      ];

  Future<void> syncOnce() async {
    // this is the main sync file that does the sync
    for (final entity in syncers) {
      await _pushEntity(entity);
      await _pullEntity(entity);
    }
  }

  Future<void> _pushEntity(SyncableEntity entity) async {
    //1. for each table/entity (todo only until remote supports more)
    //2.get the list of unsynced rows for that table
    //3.loop through the rows
    //4. push each row to the remote DB seperately (Very expensive approach but simple to implement)(batch push is more efficient)
    //5. mark as synced

    final pendingRows = await entity.getUnsyncedRowsFromLocalDB();

    for (final row in pendingRows) {
      try {
        await entity.pushUnsyncedRowsToRemoteDB(row);
        await entity.markAsSynced(
          row['id'].toString(),
        ); //  WHERE id = ? set syncStatus = 'synced'
      } catch (e) {
        debugPrint('Push failed for ${entity.entityName}: $e');
      }
    }
  }

  Future<void> _pullEntity(SyncableEntity entity) async {
    // this is null initially, but after the first sync, it will be set to the last synced time
    final lastSyncedAt = await entity.getLastSyncedAt();

    try {
      final RemoteChangesBatch batch = await entity.fetchRemoteChanges(
        lastSyncedAt,
      );

      for (final remoteRow in batch.rows) {
        await _applyWithLastWriteWins(entity, remoteRow);
      }

      final nextWatermark = _nextPullWatermark(
        previous: lastSyncedAt,
        remoteMaxUpdatedAt: batch.remoteMaxUpdatedAt,
      );
      await entity.setLastSyncedAt(nextWatermark);
    } catch (e) {
      debugPrint('Pull failed for ${entity.entityName}: $e');
    }
  }

  /// Cursor must follow server `updatedAt`, not device wall clock; otherwise
  /// rows with older timestamps never pass the client-side `isAfter` filter.
  static DateTime _nextPullWatermark({
    required DateTime? previous,
    required DateTime? remoteMaxUpdatedAt,
  }) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (remoteMaxUpdatedAt == null) {
      return previous ?? epoch;
    }
    if (previous == null) return remoteMaxUpdatedAt;
    // Heal bad metadata (e.g. old builds used DateTime.now() as the cursor).
    if (previous.isAfter(remoteMaxUpdatedAt)) return remoteMaxUpdatedAt;
    return remoteMaxUpdatedAt.isAfter(previous) ? remoteMaxUpdatedAt : previous;
  }

  Future<void> _applyWithLastWriteWins(
    SyncableEntity entity,
    Map<String, dynamic> remoteRow,
  ) async {
    final remoteId = remoteRow['id']?.toString();
    if (remoteId == null) return;
// since uuid is provided by client it should match ddb id
// if id is not found in local db it means ddb has new rows that are not synced yet
// so new rows are synced
    final localRow = await entity.getLocalRow(remoteId); 
    if (localRow == null) {
      await entity.applyRemoteRecord(remoteRow); // insert rows if id is not found in local db
      return;
    }
    final remoteVersion = _parseVersion(remoteRow['version']) ?? 0;
    final localVersion = _parseVersion(localRow['version']) ?? 0;

    if (remoteVersion > localVersion) {
      await entity.applyRemoteRecord(remoteRow);
      return;
    }
    if (remoteVersion < localVersion) {
      return;
    }

    // Same version: break ties with updatedAt (>= so equal timestamps still apply).
    final remoteUpdatedAt = _parseDateTime(remoteRow['updatedAt']);
    final localUpdatedAt = _parseDateTime(localRow['updatedAt']);

    if (remoteUpdatedAt == null || localUpdatedAt == null) {
      await entity.applyRemoteRecord(remoteRow);
      return;
    }

    if (!remoteUpdatedAt.isBefore(localUpdatedAt)) {
      await entity.applyRemoteRecord(remoteRow);
    }
  }

  int? _parseVersion(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    return null;
  }
}
