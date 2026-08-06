/// Local-first sync lifecycle for every mutable row.
enum SyncStatus {
  localOnly('LOCAL_ONLY'),
  pending('PENDING'),
  syncing('SYNCING'),
  synced('SYNCED'),
  failed('FAILED'),
  conflict('CONFLICT');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromValue(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.localOnly,
    );
  }
}
