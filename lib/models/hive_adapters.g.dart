// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveClientPendencyAdapter extends TypeAdapter<HiveClientPendency> {
  @override
  final int typeId = 0;

  @override
  HiveClientPendency read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveClientPendency(
      id: fields[0] as int?,
      clientId: fields[1] as int,
      description: fields[2] as String,
      priority: fields[3] as String,
      createdAt: fields[4] as DateTime,
      status: fields[5] as String,
      resolvedAt: fields[6] as DateTime?,
      solution: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveClientPendency obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.resolvedAt)
      ..writeByte(7)
      ..write(obj.solution);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveClientPendencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePontoRegistroAdapter extends TypeAdapter<HivePontoRegistro> {
  @override
  final int typeId = 1;

  @override
  HivePontoRegistro read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePontoRegistro(
      employeeId: fields[0] as int,
      entryType: fields[1] as String,
      timestamp: fields[2] as DateTime,
      latitude: fields[3] as double?,
      longitude: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, HivePontoRegistro obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.employeeId)
      ..writeByte(1)
      ..write(obj.entryType)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePontoRegistroAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
