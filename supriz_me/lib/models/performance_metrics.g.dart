// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_metrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PerformanceMetricsAdapter extends TypeAdapter<PerformanceMetrics> {
  @override
  final int typeId = 10;

  @override
  PerformanceMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PerformanceMetrics(
      tempsCalculMs: fields[0] as int,
      cpuUsagePercent: fields[1] as double,
      memoireUsageBytes: fields[2] as int,
      batterieDrainEstimeeMAh: fields[3] as double,
      nbRecommandations: fields[4] as int,
      nbActiviteesTraitees: fields[5] as int,
      timestamp: fields[6] as DateTime,
      poidsAdaptatifs: (fields[7] as Map).cast<String, double>(),
      raison: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceMetrics obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.tempsCalculMs)
      ..writeByte(1)
      ..write(obj.cpuUsagePercent)
      ..writeByte(2)
      ..write(obj.memoireUsageBytes)
      ..writeByte(3)
      ..write(obj.batterieDrainEstimeeMAh)
      ..writeByte(4)
      ..write(obj.nbRecommandations)
      ..writeByte(5)
      ..write(obj.nbActiviteesTraitees)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.poidsAdaptatifs)
      ..writeByte(8)
      ..write(obj.raison);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
