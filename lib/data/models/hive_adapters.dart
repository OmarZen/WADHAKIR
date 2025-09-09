import 'package:hive/hive.dart';

class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final int typeId = 0;

  @override
  DateTime read(BinaryReader reader) {
    final timestamp = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

class StringIntMapAdapter extends TypeAdapter<Map<String, int>> {
  @override
  final int typeId = 5;

  @override
  Map<String, int> read(BinaryReader reader) {
    final length = reader.readInt();
    final Map<String, int> map = {};
    for (var i = 0; i < length; i++) {
      final key = reader.readString();
      final value = reader.readInt();
      map[key] = value;
    }
    return map;
  }

  @override
  void write(BinaryWriter writer, Map<String, int> obj) {
    writer.writeInt(obj.length);
    obj.forEach((key, value) {
      writer.writeString(key);
      writer.writeInt(value);
    });
  }
}
