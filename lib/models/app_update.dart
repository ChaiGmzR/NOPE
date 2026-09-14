class AppUpdate {
  const AppUpdate({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.notes,
    this.digest,
  });

  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String notes;
  final String? digest;

  factory AppUpdate.fromMap(Map<Object?, Object?> map) {
    return AppUpdate(
      currentVersion: map['currentVersion'] as String? ?? '0.1.0',
      latestVersion: map['latestVersion'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      digest: map['digest'] as String?,
    );
  }
}
