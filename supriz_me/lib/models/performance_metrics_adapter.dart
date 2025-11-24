import 'package:hive/hive.dart';
import 'performance_metrics.dart';

class PerformanceMetricsAdapter extends TypeAdapter<PerformanceMetrics> {
  @override
  final int typeId = 10;

  @override
  PerformanceMetrics read(BinaryReader reader) {
    final tempsCalculMs = reader.readInt();
    final cpuUsagePercent = reader.readDouble();
    final memoireUsageBytes = reader.readInt();
    final batterieDrainEstimeeMAh = reader.readDouble();
    final nbRecommandations = reader.readInt();
    final nbActiviteesTraitees = reader.readInt();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final poidsAdaptatifs =
        Map<String, double>.from(reader.readMap().cast());
    final raison = reader.readString();

    return PerformanceMetrics(
      tempsCalculMs: tempsCalculMs,
      cpuUsagePercent: cpuUsagePercent,
      memoireUsageBytes: memoireUsageBytes,
      batterieDrainEstimeeMAh: batterieDrainEstimeeMAh,
      nbRecommandations: nbRecommandations,
      nbActiviteesTraitees: nbActiviteesTraitees,
      timestamp: timestamp,
      poidsAdaptatifs: poidsAdaptatifs,
      raison: raison,
    );
  }

  @override
  void write(BinaryWriter writer, PerformanceMetrics obj) {
    writer.writeInt(obj.tempsCalculMs);
    writer.writeDouble(obj.cpuUsagePercent);
    writer.writeInt(obj.memoireUsageBytes);
    writer.writeDouble(obj.batterieDrainEstimeeMAh);
    writer.writeInt(obj.nbRecommandations);
    writer.writeInt(obj.nbActiviteesTraitees);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeMap(obj.poidsAdaptatifs);
    writer.writeString(obj.raison);
  }
}
