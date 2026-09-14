class AppLockPermissionStatus {
  final bool usageAccessGranted;
  final bool overlayGranted;

  const AppLockPermissionStatus({
    required this.usageAccessGranted,
    required this.overlayGranted,
  });

  bool get allRequiredGranted => usageAccessGranted && overlayGranted;

  factory AppLockPermissionStatus.fromMap(Map<dynamic, dynamic> map) {
    return AppLockPermissionStatus(
      usageAccessGranted: map['usageAccessGranted'] as bool? ?? false,
      overlayGranted: map['overlayGranted'] as bool? ?? false,
    );
  }
}
