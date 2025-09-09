// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasanat_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HasanatRecordAdapter extends TypeAdapter<HasanatRecord> {
  @override
  final int typeId = 3;

  @override
  HasanatRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HasanatRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      itemId: fields[2] as String,
      points: fields[3] as int,
      notes: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HasanatRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HasanatRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
