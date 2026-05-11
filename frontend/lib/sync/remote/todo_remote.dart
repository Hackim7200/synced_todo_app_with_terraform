// Handles GraphQL calls to push and pull todo records from the backend.
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:frontend/sync/remote_changes_batch.dart';

class TodoRemote {
  const TodoRemote();

  static const String _graphqlApiName = 'PomodoroPlansGraphQLApi';

  Future<void> upsertTodo(Map<String, dynamic> todo) async {
    final input = <String, dynamic>{...todo};

    final id = input['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Cannot upsert todo without an id.');
    }

    final exists = await _todoExists(id);
    final document = exists
        ? r'''
        mutation UpsertTodo($input: UpdateTodoInput!) {
          updateTodo(input: $input) { id }
        }
      '''
        : r'''
        mutation UpsertTodo($input: CreateTodoInput!) {
          createTodo(input: $input) { id }
        }
      ''';

    final request = GraphQLRequest<String>(
      apiName: _graphqlApiName,
      document: document,
      variables: {'input': input},
    );

    final response = await Amplify.API.mutate(request: request).response;
    _throwIfGraphQLErrors(response.errors, operation: 'upsert todo');
    _requireData(response.data);
  }

  /// Fetches every todo via [listTodos] (paginated).
  ///
  /// [rows] are **not** filtered by [since]. A time threshold would be wrong
  /// here: [remoteMaxUpdatedAt] is the max `updatedAt` in the snapshot, so any
  /// row older than that max (e.g. deletes written with another device's clock)
  /// would never pass `updatedAt > since` and would never be merged — while the
  /// server can still show `isDeleted: true` for those ids.
  ///
  /// The coordinator still uses [remoteMaxUpdatedAt] with [since] only for the
  /// stored sync watermark, not for choosing which rows to apply.
  Future<RemoteChangesBatch> getTodosSince(DateTime? since) async {
    final allItems = <Map<String, dynamic>>[];
    String? nextToken;

    do {
      final variables = <String, dynamic>{
        'limit': 200,
        if (nextToken != null) 'nextToken': nextToken,
      };

      final request = GraphQLRequest<String>(
        apiName: _graphqlApiName,
        document: r'''
          query ListTodosForSync($limit: Int, $nextToken: String) {
            listTodos(limit: $limit, nextToken: $nextToken) {
              items {
                id
                title
                isCompleted
                version
                updatedAt
                createdAt
                isDeleted
              }
              nextToken
            }
          }
        ''',
        variables: variables,
      );

      final response = await Amplify.API.query(request: request).response;
      _throwIfGraphQLErrors(response.errors, operation: 'list todos');
      final payload = _requireData(response.data);
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final root = decoded['listTodos'] as Map<String, dynamic>? ?? const {};
      final items = root['items'] as List<dynamic>? ?? const [];
      allItems.addAll(items.whereType<Map<String, dynamic>>());

      final token = root['nextToken'];
      nextToken = (token is String && token.isNotEmpty) ? token : null;
    } while (nextToken != null);

    DateTime? remoteMaxUpdatedAt;
    for (final row in allItems) {
      final u = _parseUpdatedAt(row['updatedAt']);
      if (u == null) continue;
      if (remoteMaxUpdatedAt == null || u.isAfter(remoteMaxUpdatedAt)) {
        remoteMaxUpdatedAt = u;
      }
    }

    return RemoteChangesBatch(
      rows: allItems,
      remoteMaxUpdatedAt: remoteMaxUpdatedAt,
    );
  }

  static DateTime? _parseUpdatedAt(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    return null;
  }

  Future<bool> _todoExists(String id) async {
    final request = GraphQLRequest<String>(
      apiName: _graphqlApiName,
      document: r'''
        query GetTodoForUpsert($id: ID!) {
          getTodo(id: $id) { id }
        }
      ''',
      variables: {'id': id},
    );

    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      final notFound = response.errors.any(
        (e) =>
            e.errorType == 'NotFound' ||
            e.message.toLowerCase().contains('not found'),
      );
      if (notFound) return false;
      _throwIfGraphQLErrors(response.errors, operation: 'check todo existence');
    }

    final payload = response.data;
    if (payload == null || payload.isEmpty) return false;
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return decoded['getTodo'] != null;
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
