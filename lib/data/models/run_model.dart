import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'run_model.g.dart';

/// Режимы забега.
enum RunMode { sprint, snake, timed }

extension RunModeX on RunMode {
  String get label {
    switch (this) {
      case RunMode.sprint:
        return 'Спринт';
      case RunMode.snake:
        return 'Змейка';
      case RunMode.timed:
        return 'На время';
    }
  }
}

/// Модель забега. Хранится и в Firestore (`runs/{id}`), и локально в Hive,
/// когда нет интернета — поэтому она HiveObject с ручным типизированным адаптером
/// (см. run_model.g.dart), а не сгенерированным build_runner (чтобы проект
/// собирался сразу, без обязательного шага генерации кода).
@HiveType(typeId: 1)
class RunModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final RunMode mode;
  @HiveField(3)
  final DateTime startTime;
  @HiveField(4)
  final DateTime endTime;
  @HiveField(5)
  final int totalTimeSeconds;
  @HiveField(6)
  final double distanceKm;
  @HiveField(7)
  final double caloriesBurned;

  /// Время (в секундах от старта) прохождения каждого чекпоинта.
  /// Заполняется только для режима "Змейка".
  @HiveField(8)
  final List<int>? checkpointTimes;

  /// GPS-трек для режима "гонка с собой" (призрак): {lat, lng, timestamp}.
  @HiveField(9)
  final List<Map<String, dynamic>> gpsTrack;

  /// false, если сработал анти-чит (см. RunCubit) — тогда забег не идёт в рекорды.
  @HiveField(10)
  final bool isValidForRecord;

  /// true, если забег уже успешно синхронизирован в Firestore.
  @HiveField(11)
  final bool synced;

  RunModel({
    required this.id,
    required this.userId,
    required this.mode,
    required this.startTime,
    required this.endTime,
    required this.totalTimeSeconds,
    required this.distanceKm,
    required this.caloriesBurned,
    this.checkpointTimes,
    this.gpsTrack = const [],
    this.isValidForRecord = true,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'mode': mode.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalTimeSeconds': totalTimeSeconds,
      'distanceKm': distanceKm,
      'caloriesBurned': caloriesBurned,
      'checkpointTimes': checkpointTimes,
      'gpsTrack': gpsTrack,
      'isValidForRecord': isValidForRecord,
    };
  }

  factory RunModel.fromMap(Map<String, dynamic> map) {
    return RunModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      mode: RunMode.values.byName(map['mode'] as String),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      totalTimeSeconds: map['totalTimeSeconds'] as int,
      distanceKm: (map['distanceKm'] as num).toDouble(),
      caloriesBurned: (map['caloriesBurned'] as num).toDouble(),
      checkpointTimes: (map['checkpointTimes'] as List?)?.map((e) => e as int).toList(),
      gpsTrack: (map['gpsTrack'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
      isValidForRecord: map['isValidForRecord'] as bool? ?? true,
      synced: true, // если пришло из Firestore — значит уже синхронизировано
    );
  }

  RunModel copyWith({bool? synced}) {
    return RunModel(
      id: id,
      userId: userId,
      mode: mode,
      startTime: startTime,
      endTime: endTime,
      totalTimeSeconds: totalTimeSeconds,
      distanceKm: distanceKm,
      caloriesBurned: caloriesBurned,
      checkpointTimes: checkpointTimes,
      gpsTrack: gpsTrack,
      isValidForRecord: isValidForRecord,
      synced: synced ?? this.synced,
    );
  }
}
