// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_list_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallListModelAdapter extends TypeAdapter<CallListModel> {
  @override
  final int typeId = 0;

  @override
  CallListModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallListModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      name: fields[2] as String,
      status: fields[3] as String,
      createdAt: fields[4] as DateTime,
      progress: fields[5] as double,
      totalItems: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CallListModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.totalItems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallListModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CallListItemModelAdapter extends TypeAdapter<CallListItemModel> {
  @override
  final int typeId = 1;

  @override
  CallListItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallListItemModel(
      id: fields[0] as String,
      listId: fields[1] as String,
      name: fields[2] as String?,
      phone: fields[3] as String,
      status: fields[4] as String,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CallListItemModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.listId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallListItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
