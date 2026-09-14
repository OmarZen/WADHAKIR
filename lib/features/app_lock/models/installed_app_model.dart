import 'dart:typed_data';

class InstalledAppModel {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final Uint8List? iconBytes;

  const InstalledAppModel({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    required this.iconBytes,
  });

  factory InstalledAppModel.fromMap(Map<dynamic, dynamic> map) {
    return InstalledAppModel(
      packageName: (map['packageName'] ?? '').toString(),
      appName: (map['appName'] ?? '').toString(),
      isSystemApp: map['isSystemApp'] as bool? ?? false,
      iconBytes: map['iconBytes'] as Uint8List?,
    );
  }
}
