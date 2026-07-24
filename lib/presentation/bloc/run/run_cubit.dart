import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/data/models/route_model.dart';
import 'package:streetrun/data/models/run_model.dart';
import 'package:streetrun/data/repositories/run_repository.dart';
import 'package:streetrun/data/services/gps_service.dart';
import 'package:streetrun/data/services/tts_service.dart';

sealed class RunState extends Equatable {
  const RunState();
  @override
  List<Object?> get props => [];
}

class RunIdle extends RunState {}

/// Маршрут сгенерирован, карта показана, ждём нажатия "Старт".
class RunPreparing extends RunState {
  final RouteModel route;
  final List<LatLng>? ghostTrack;
  final int? ghostTotalSeconds;
  final double? friendTargetSeconds;

  const RunPreparing(
    this.route, {
    this.ghostTrack,
    this.ghostTotalSeconds,
    this.friendTargetSeconds,
  });

  @override
  List<Object?> get props => [route, ghostTrack, friendTargetSeconds];
}

class RunActive extends RunState {
  final RouteModel route;
  final int elapsedSeconds;
  final double distanceKm;
  final List<LatLng> track;
  final int nextCheckpointIndex;
  final int violationsCount;
  final List<LatLng>? ghostTrack;
  final int? ghostTotalSeconds;
  final double? friendTargetSeconds;
  final int tick; // просто счётчик обновлений, чтобы состояние всегда было "новым"

  const RunActive({
    required this.route,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.track,
    required this.nextCheckpointIndex,
    required this.violationsCount,
    required this.tick,
    this.ghostTrack,
    this.ghostTotalSeconds,
    this.friendTargetSeconds,
  });

  int get totalCheckpoints => route.checkpoints.length;

  RunActive copyWith({
    int? elapsedSeconds,
    double? distanceKm,
    List<LatLng>? track,
    int? nextCheckpointIndex,
    int? violationsCount,
  }) {
    return RunActive(
      route: route,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      track: track ?? this.track,
      nextCheckpointIndex: nextCheckpointIndex ?? this.nextCheckpointIndex,
      violationsCount: violationsCount ?? this.violationsCount,
      ghostTrack: ghostTrack,
      ghostTotalSeconds: ghostTotalSeconds,
      friendTargetSeconds: friendTargetSeconds,
      tick: tick + 1,
    );
  }

  @override
  List<Object?> get props => [tick];
}

class RunFinished extends RunState {
  final RunModel result;
  final double? comparisonSeconds; // время цели (призрак или друг), если было
  final String? comparisonLabel;

  const RunFinished(this.result, {this.comparisonSeconds, this.comparisonLabel});

  @override
  List<Object?> get props => [result];
}

/// Cubit одного забега: от выбора режима до сохранения результата.
/// Живёт всё время, пока открыт экран забега/финиша; после возврата в меню
/// стоит вызывать reset(), чтобы следующий забег начинался с чистого состояния.
class RunCubit extends Cubit<RunState> {
  final GpsService _gpsService;
  final TtsService _ttsService;
  final RunRepository _runRepository;

  RunCubit(this._gpsService, this._ttsService, this._runRepository) : super(RunIdle());

  // ---- внутреннее состояние забега (не часть публичного State) ----
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  final List<LatLng> _track = [];
  final List<Map<String, dynamic>> _gpsTrack = [];
  final List<int> _checkpointTimes = [];
  final List<double> _recentSpeedsKmh = [];

  double _distanceMeters = 0;
  LatLng? _lastPoint;
  DateTime? _lastPointAt;
  DateTime? _speedViolationSince;
  DateTime? _lastPaceMessageAt;
  int _violationsCount = 0;
  int _nextCheckpointIndex = 0;
  int _elapsedSeconds = 0;
  bool _halfwayAnnounced = false;

  String? _userId;
  String? _runId;
  RouteModel? _route;

  final _messageController = StreamController<String>.broadcast();

  /// Транзиентные сообщения для SnackBar на экране забега (не хранятся в state).
  Stream<String> get messages => _messageController.stream;

  /// Строит маршрут для выбранного режима от текущей позиции пользователя.
  Future<RouteModel> generateRoute(RunMode mode) async {
    final hasPermission = await _gpsService.ensureLocationPermission();
    if (!hasPermission) {
      throw Exception('Нет доступа к геолокации. Разрешите её в настройках телефона.');
    }
    final position = await _gpsService.getCurrentPosition();
    return _gpsService.generateRoute(mode, position);
  }

  void prepareRun(
    RouteModel route, {
    List<LatLng>? ghostTrack,
    int? ghostTotalSeconds,
    double? friendTargetSeconds,
  }) {
    _route = route;
    emit(RunPreparing(
      route,
      ghostTrack: ghostTrack,
      ghostTotalSeconds: ghostTotalSeconds,
      friendTargetSeconds: friendTargetSeconds,
    ));
  }

  /// Подтягивает последний забег этого режима как "призрака" — трек серой
  /// линией на карте плюс время как ориентир.
  Future<void> enableGhostRace(String userId) async {
    final current = state;
    if (current is! RunPreparing) return;
    final lastRun = await _runRepository.getLastRunForGhost(userId, current.route.mode);
    if (lastRun == null) {
      _messageController.add('Нет прошлых забегов в этом режиме — не с кем соревноваться');
      return;
    }
    final ghostTrack = lastRun.gpsTrack
        .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
        .toList();
    emit(RunPreparing(current.route, ghostTrack: ghostTrack, ghostTotalSeconds: lastRun.totalTimeSeconds));
  }

  /// Подтягивает лучшее время друга в этом режиме как цель.
  Future<void> enableFriendRace(String friendUid) async {
    final current = state;
    if (current is! RunPreparing) return;
    final target = await _runRepository.getFriendBestSeconds(friendUid, current.route.mode);
    if (target == null) {
      _messageController.add('У друга пока нет результата в этом режиме');
      return;
    }
    emit(RunPreparing(current.route, friendTargetSeconds: target));
  }

  Future<void> startRun({required String userId}) async {
    final current = state;
    if (current is! RunPreparing) return;

    _userId = userId;
    _runId = DateTime.now().microsecondsSinceEpoch.toString();
    _route = current.route;
    _track.clear();
    _gpsTrack.clear();
    _checkpointTimes.clear();
    _recentSpeedsKmh.clear();
    _distanceMeters = 0;
    _lastPoint = null;
    _lastPointAt = null;
    _speedViolationSince = null;
    _violationsCount = 0;
    _nextCheckpointIndex = 0;
    _elapsedSeconds = 0;
    _halfwayAnnounced = false;

    _ttsService.speak(AppStrings.ttsStart);
    _messageController.add(AppStrings.ttsStart);

    emit(RunActive(
      route: current.route,
      elapsedSeconds: 0,
      distanceKm: 0,
      track: const [],
      nextCheckpointIndex: 0,
      violationsCount: 0,
      tick: 0,
      ghostTrack: current.ghostTrack,
      ghostTotalSeconds: current.ghostTotalSeconds,
      friendTargetSeconds: current.friendTargetSeconds,
    ));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _positionSub = _gpsService.watchPosition().listen(_onPosition);
  }

  void _onTick() {
    _elapsedSeconds++;
    final current = state;
    if (current is RunActive) {
      emit(current.copyWith(elapsedSeconds: _elapsedSeconds));
    }
  }

  void _onPosition(Position position) {
    final current = state;
    if (current is! RunActive || _route == null) return;

    final point = LatLng(position.latitude, position.longitude);
    final now = DateTime.now();

    if (_lastPoint != null && _lastPointAt != null) {
      final deltaMeters = _gpsService.distanceMeters(_lastPoint!, point);
      final deltaSeconds = now.difference(_lastPointAt!).inMilliseconds / 1000.0;
      final speedKmh = deltaSeconds > 0 ? (deltaMeters / deltaSeconds) * 3.6 : 0.0;

      _distanceMeters += deltaMeters;
      _trackSpeedForPaceCues(speedKmh);
      _checkAntiCheat(speedKmh, now);
    }

    _lastPoint = point;
    _lastPointAt = now;
    _track.add(point);
    _gpsTrack.add({
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': now.millisecondsSinceEpoch,
    });

    _checkCheckpoints(point);
    _checkHalfway();

    emit(current.copyWith(
      distanceKm: _distanceMeters / 1000,
      track: List.unmodifiable(_track),
      nextCheckpointIndex: _nextCheckpointIndex,
      violationsCount: _violationsCount,
    ));
  }

  /// Простая эвристика для голосовых реплик "сбавил/прибавил темп":
  /// сравниваем текущую скорость со средней за последние несколько замеров.
  void _trackSpeedForPaceCues(double speedKmh) {
    _recentSpeedsKmh.add(speedKmh);
    if (_recentSpeedsKmh.length > 5) _recentSpeedsKmh.removeAt(0);
    if (_recentSpeedsKmh.length < 5) return;

    final avg = _recentSpeedsKmh.reduce((a, b) => a + b) / _recentSpeedsKmh.length;
    if (avg < 1.5) return; // почти стоим на месте — рано судить о темпе

    final cooldownOk = _lastPaceMessageAt == null ||
        DateTime.now().difference(_lastPaceMessageAt!) > const Duration(seconds: 20);
    if (!cooldownOk) return;

    if (speedKmh < avg * 0.5) {
      _lastPaceMessageAt = DateTime.now();
      _ttsService.speak(AppStrings.ttsSlowDown);
      _messageController.add(AppStrings.ttsSlowDown);
    } else if (speedKmh > avg * 1.5) {
      _lastPaceMessageAt = DateTime.now();
      _ttsService.speak(AppStrings.ttsSpeedUp);
      _messageController.add(AppStrings.ttsSpeedUp);
    }
  }

  /// Если скорость держится выше 15 км/ч дольше 30 секунд — это уже не бег
  /// и не шаг, а похоже на транспорт. Больше 3 таких эпизодов — забег не
  /// идёт в рекорды (см. RunRepository._maybeUpdateRecord).
  void _checkAntiCheat(double speedKmh, DateTime now) {
    const speedLimitKmh = 15.0;
    if (speedKmh > speedLimitKmh) {
      _speedViolationSince ??= now;
      if (now.difference(_speedViolationSince!) >= const Duration(seconds: 30)) {
        _violationsCount++;
        _speedViolationSince = null;
        _ttsService.speak(AppStrings.ttsAntiCheatWarning);
        _messageController.add(AppStrings.ttsAntiCheatWarning);
      }
    } else {
      _speedViolationSince = null;
    }
  }

  void _checkCheckpoints(LatLng point) {
    if (_route == null) return;
    if (_nextCheckpointIndex >= _route!.checkpoints.length) return;

    final checkpoint = _route!.checkpoints[_nextCheckpointIndex];
    final distance = _gpsService.distanceMeters(point, checkpoint.position);

    if (distance <= 20) {
      checkpoint.reached = true;
      _nextCheckpointIndex++;
      _checkpointTimes.add(_elapsedSeconds);

      final remaining = _route!.checkpoints.length - _nextCheckpointIndex;
      if (remaining > 0) {
        _ttsService.speak(AppStrings.ttsCheckpoint(remaining));
        _messageController.add(AppStrings.ttsCheckpoint(remaining));
      } else {
        _finishRun();
      }
    }
  }

  void _checkHalfway() {
    if (_halfwayAnnounced || _route == null) return;
    if (_route!.plannedDistanceKm <= 0) return;
    if (_distanceMeters / 1000 >= _route!.plannedDistanceKm / 2) {
      _halfwayAnnounced = true;
      _ttsService.speak(AppStrings.ttsHalfway);
      _messageController.add(AppStrings.ttsHalfway);
    }
  }

  /// Кнопка "Стоп" — досрочное завершение забега текущими показателями.
  Future<void> stopRun() => _finishRun();

  Future<void> _finishRun() async {
    _timer?.cancel();
    await _positionSub?.cancel();

    final current = state;
    if (current is! RunActive || _userId == null || _runId == null || _route == null) {
      emit(RunIdle());
      return;
    }

    _ttsService.speak(AppStrings.ttsFinish);
    _messageController.add(AppStrings.ttsFinish);

    final distanceKm = _distanceMeters / 1000;
    final avgSpeedKmh =
        _elapsedSeconds > 0 ? distanceKm / (_elapsedSeconds / 3600) : 0.0;
    // Порог "бег или ходьба" не задан в ТЗ явно — берём разумную границу
    // темпа, ниже которой это уже больше похоже на ходьбу (MET 3.5), а
    // выше — на бег (MET 8.0), как и требуют две формулы из ТЗ.
    final met = avgSpeedKmh >= 6.5 ? 8.0 : 3.5;
    const weightKg = 70.0; // пока константа, см. ТЗ — вес в профиль добавим позже
    final calories = met * weightKg * (_elapsedSeconds / 3600);

    final isValid = _violationsCount <= 3;

    final run = RunModel(
      id: _runId!,
      userId: _userId!,
      mode: _route!.mode,
      startTime: DateTime.now().subtract(Duration(seconds: _elapsedSeconds)),
      endTime: DateTime.now(),
      totalTimeSeconds: _elapsedSeconds,
      distanceKm: distanceKm,
      caloriesBurned: calories,
      checkpointTimes: _route!.mode == RunMode.snake ? List.of(_checkpointTimes) : null,
      gpsTrack: List.of(_gpsTrack),
      isValidForRecord: isValid,
    );

    try {
      await _runRepository.saveRun(run);
    } catch (_) {
      // saveRun сам уходит в офлайн-буфер при ошибке — здесь всё равно
      // показываем пользователю результат, а не техническую ошибку сети
    }

    final finishedFrom = current; // RunActive хранит те же ghost/friend поля, что и RunPreparing
    double? comparisonSeconds;
    String? comparisonLabel;
    if (finishedFrom.friendTargetSeconds != null) {
      comparisonSeconds = finishedFrom.friendTargetSeconds;
      comparisonLabel = 'Время друга на этом маршруте';
    } else if (finishedFrom.ghostTotalSeconds != null) {
      comparisonSeconds = finishedFrom.ghostTotalSeconds!.toDouble();
      comparisonLabel = 'Ваш прошлый результат';
    }

    emit(RunFinished(run, comparisonSeconds: comparisonSeconds, comparisonLabel: comparisonLabel));
  }

  /// Сбросить состояние перед новым забегом (вызывается при возврате в меню).
  void reset() {
    _timer?.cancel();
    _positionSub?.cancel();
    _route = null;
    _userId = null;
    _runId = null;
    emit(RunIdle());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _positionSub?.cancel();
    _messageController.close();
    return super.close();
  }
}
