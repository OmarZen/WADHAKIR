// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasanat_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HasanatItemAdapter extends TypeAdapter<HasanatItem> {
  @override
  final int typeId = 2;

  @override
  HasanatItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HasanatItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      points: fields[3] as int,
      category: fields[4] as HasanatCategory,
      isDefault: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HasanatItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HasanatItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HasanatCategoryAdapter extends TypeAdapter<HasanatCategory> {
  @override
  final int typeId = 1;

  @override
  HasanatCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HasanatCategory.fard;
      case 1:
        return HasanatCategory.sunnah;
      case 2:
        return HasanatCategory.nafl;
      case 3:
        return HasanatCategory.other;
      default:
        return HasanatCategory.fard;
    }
  }

  @override
  void write(BinaryWriter writer, HasanatCategory obj) {
    switch (obj) {
      case HasanatCategory.fard:
        writer.writeByte(0);
        break;
      case HasanatCategory.sunnah:
        writer.writeByte(1);
        break;
      case HasanatCategory.nafl:
        writer.writeByte(2);
        break;
      case HasanatCategory.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HasanatCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
