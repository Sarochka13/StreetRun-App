import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:streetrun/data/models/route_model.dart';
import 'package:streetrun/data/models/run_model.dart';

/// Сервис для всего, что связано с GPS: разрешения, поток позиций
/// (в т.ч. в фоне), расчёт расстояний и генерация маршрута для забега.
class GpsService {
  static const double earthRadiusMeters = 6371000;

  /// Проверяет и при необходимости запрашивает разрешение на геолокацию.
  /// Возвращает true, если можно продолжать (whileInUse или always).
  Future<bool> ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  /// Поток позиций с интервалом 3-5 секунд, который продолжает работать,
  /// даже если экран выключен / приложение свёрнуто (foreground-service на Android).
  Stream<Position> watchPosition() {
    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // метров, минимальное смещение для нового события
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'StreetRun',
          notificationText: 'Забег активен — запись GPS-трека продолжается',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  double distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  /// Точка на расстоянии [distanceMeters] от [start] по азимуту [bearingDegrees].
  LatLng destinationPoint(LatLng start, double distanceMeters, double bearingDegrees) {
    final d = distanceMeters / earthRadiusMeters;
    final brng = bearingDegrees * math.pi / 180;
    final lat1 = start.latitude * math.pi / 180;
    final lon1 = start.longitude * math.pi / 180;

    final lat2 = math.asin(math.sin(lat1) * math.cos(d) +
        math.cos(lat1) * math.sin(d) * math.cos(brng));
    final lon2 = lon1 +
        math.atan2(
          math.sin(brng) * math.sin(d) * math.cos(lat1),
          math.cos(d) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  /// Генерирует маршрут для выбранного режима от текущей позиции пользователя.
  /// В проекте нет отдельного сервера маршрутов — точки считаются на устройстве.
  RouteModel generateRoute(RunMode mode, Position current) {
    final start = LatLng(current.latitude, current.longitude);
    final random = math.Random();

    switch (mode) {
      case RunMode.sprint:
        final distance = 500 + random.nextDouble() * 2500; // 500..3000 м
        final bearing = random.nextDouble() * 360;
        final end = destinationPoint(start, distance, bearing);
        return RouteModel(
          mode: mode,
          startPoint: start,
          checkpoints: [Checkpoint(position: end)],
          plannedDistanceKm: distance / 1000,
        );

      case RunMode.snake:
        final checkpoints = <Checkpoint>[];
        double total = 0;
        var last = start;
        for (var i = 0; i < 5; i++) {
          // Точки по кругу с разбросом, чтобы не лепились друг на друга,
          // но все в пределах 1 км от старта.
          final bearing = (360 / 5) * i + random.nextDouble() * 40 - 20;
          final distanceFromStart = 200 + random.nextDouble() * 800; // до 1000 м
          final point = destinationPoint(start, distanceFromStart, bearing);
          total += distanceMeters(last, point);
          checkpoints.add(Checkpoint(position: point));
          last = point;
        }
        return RouteModel(
          mode: mode,
          startPoint: start,
          checkpoints: checkpoints,
          plannedDistanceKm: total / 1000,
        );

      case RunMode.timed:
        // Петля из 4 точек, возвращающаяся к старту, суммарно 1-2 км.
        final loopPoints = <Checkpoint>[];
        final legDistance = (1000 + random.nextDouble() * 1000) / 4; // на каждую сторону петли
        double total = 0;
        var last = start;
        for (var i = 0; i < 4; i++) {
          final bearing = 90.0 * i;
          final point = destinationPoint(last, legDistance, bearing);
          total += legDistance;
          loopPoints.add(Checkpoint(position: point));
          last = point;
        }
        total += distanceMeters(last, start);
        loopPoints.add(Checkpoint(position: start)); // возврат к старту = финиш круга
        return RouteModel(
          mode: mode,
          startPoint: start,
          checkpoints: loopPoints,
          plannedDistanceKm: total / 1000,
        );
    }
  }
}
