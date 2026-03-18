// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncTaskModelAdapter extends TypeAdapter<SyncTaskModel> {
  @override
  final int typeId = 2;

  @override
  SyncTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncTaskModel(
      id: fields[0] as String,
      itemId: fields[1] as String,
      status: fields[2] as String,
      notes: fields[3] as String?,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncTaskModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncTaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
