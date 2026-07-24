// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RunModelAdapter extends TypeAdapter<RunModel> {
  @override
  final int typeId = 1;

  @override
  RunModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RunModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      mode: fields[2] as RunMode,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime,
      totalTimeSeconds: fields[5] as int,
      distanceKm: fields[6] as double,
      caloriesBurned: fields[7] as double,
      checkpointTimes: (fields[8] as List?)?.cast<int>(),
      gpsTrack: (fields[9] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      isValidForRecord: fields[10] as bool,
      synced: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RunModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.totalTimeSeconds)
      ..writeByte(6)
      ..write(obj.distanceKm)
      ..writeByte(7)
      ..write(obj.caloriesBurned)
      ..writeByte(8)
      ..write(obj.checkpointTimes)
      ..writeByte(9)
      ..write(obj.gpsTrack)
      ..writeByte(10)
      ..write(obj.isValidForRecord)
      ..writeByte(11)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
