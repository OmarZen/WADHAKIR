// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasanat_day_summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HasanatDaySummaryAdapter extends TypeAdapter<HasanatDaySummary> {
  @override
  final int typeId = 4;

  @override
  HasanatDaySummary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HasanatDaySummary(
      date: fields[0] as DateTime,
      totalPoints: fields[1] as int,
      completedItems: fields[2] as int,
      pointsByCategory: (fields[3] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, HasanatDaySummary obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalPoints)
      ..writeByte(2)
      ..write(obj.completedItems)
      ..writeByte(3)
      ..write(obj.pointsByCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HasanatDaySummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
