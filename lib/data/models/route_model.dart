import 'package:latlong2/latlong.dart';
import 'package:streetrun/data/models/run_model.dart';

/// Один чекпоинт на маршруте.
class Checkpoint {
  final LatLng position;
  bool reached;

  Checkpoint({required this.position, this.reached = false});
}

/// Сгенерированный маршрут для конкретного забега. В проекте нет отдельного
/// бэкенда маршрутов — маршрут генерируется на устройстве от текущей позиции
/// пользователя (см. GpsService.generateRoute), а эта модель просто
/// переносит его между экраном выбора режима и экраном забега.
class RouteModel {
  final RunMode mode;
  final LatLng startPoint;
  final List<Checkpoint> checkpoints; // для sprint это только точка Б, для timed — точки петли
  final double plannedDistanceKm;

  const RouteModel({
    required this.mode,
    required this.startPoint,
    required this.checkpoints,
    required this.plannedDistanceKm,
  });
}
