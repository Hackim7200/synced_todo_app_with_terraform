/// Result of a remote pull used to advance the incremental sync cursor.
class RemoteChangesBatch {
  const RemoteChangesBatch({
    required this.rows,
    this.remoteMaxUpdatedAt,
  });

  final List<Map<String, dynamic>> rows;
  final DateTime? remoteMaxUpdatedAt;
}
