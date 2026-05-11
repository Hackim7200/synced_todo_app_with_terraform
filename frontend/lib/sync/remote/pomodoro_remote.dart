// Handles GraphQL calls to push and pull pomodoro records from the backend.
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:frontend/sync/remote_changes_batch.dart';

class PomodoroRemote {
  const PomodoroRemote();

  static const String _graphqlApiName = 'PomodoroPlansGraphQLApi';

  Future<void> upsertPomodoro(Map<String, dynamic> pomodoro) async {
    final request = GraphQLRequest<String>(
      apiName: _graphqlApiName,
      document: r'''
        mutation UpsertPomodoro($input: UpdatePomodoroInput!) {
          updatePomodoro(input: $input) { id }
        }
      ''',
      variables: {'input': pomodoro},
    );

    final response = await Amplify.API.mutate(request: request).response;
    _throwIfGraphQLErrors(response.errors, operation: 'upsert pomodoro');
    _requireData(response.data);
  }

  Future<RemoteChangesBatch> getPomodorosSince(DateTime? since) async {
    final updatedAfter = (since ?? DateTime.fromMillisecondsSinceEpoch(0))
        .toUtc()
        .toIso8601String();

    final request = GraphQLRequest<String>(
      apiName: _graphqlApiName,
      document: r'''
        query ListPomodorosSince($updatedAfter: AWSDateTime!) {
          listPomodoros(updatedAfter: $updatedAfter) {
            items {
              id
              todoId
              durationMinutes
              startTime
              endTime
              completed
              version
              updatedAt
              createdAt
              isDeleted
              syncStatus
            }
          }
        }
      ''',
      variables: {'updatedAfter': updatedAfter},
    );

    final response = await Amplify.API.query(request: request).response;
    _throwIfGraphQLErrors(response.errors, operation: 'list pomodoros');
    final payload = _requireData(response.data);
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final root = decoded['listPomodoros'] as Map<String, dynamic>? ?? const {};
    final items = root['items'] as List<dynamic>? ?? const [];
    final rows = items.whereType<Map<String, dynamic>>().toList();
    DateTime? remoteMaxUpdatedAt;
    for (final row in rows) {
      final u = _parseUpdatedAt(row['updatedAt']);
      if (u == null) continue;
      if (remoteMaxUpdatedAt == null || u.isAfter(remoteMaxUpdatedAt)) {
        remoteMaxUpdatedAt = u;
      }
    }
    return RemoteChangesBatch(rows: rows, remoteMaxUpdatedAt: remoteMaxUpdatedAt);
  }

  static DateTime? _parseUpdatedAt(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    return null;
  }

  static String _requireData(String? data) {
    if (data == null || data.isEmpty) {
      throw Exception('GraphQL response data was empty.');
    }
    return data;
  }

  static void _throwIfGraphQLErrors(
    List<GraphQLResponseError> errors, {
    required String operation,
  }) {
    if (errors.isNotEmpty) {
      throw Exception(
        'Failed to $operation: ${errors.map((e) => e.message).join(', ')}',
      );
    }
  }
}
