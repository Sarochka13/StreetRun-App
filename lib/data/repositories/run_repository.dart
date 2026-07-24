import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:streetrun/data/models/run_model.dart';
import 'package:streetrun/data/models/user_model.dart';
import 'package:streetrun/data/services/firebase_service.dart';
import 'package:streetrun/data/services/hive_service.dart';

/// Репозиторий забегов. Основная сложность — офлайн-режим: если нет
/// интернета, забег уходит в Hive, а не теряется, и досылается в Firestore
/// автоматически при восстановлении сети (см. подписку в конструкторе).
class RunRepository {
  final AppFirebaseService _firebaseService;
  final HiveService _hiveService;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  RunRepository(
    this._firebaseService,
    this._hiveService, {
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity() {
    // Как только сеть появилась — пробуем дослать всё, что скопилось в Hive.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncOfflineRuns();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<bool> _hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<void> saveRun(RunModel run) async {
    if (!await _hasInternet()) {
      await _hiveService.saveRun(run);
      return;
    }
    try {
      await _uploadRun(run);
    } catch (_) {
      // интернет мог пропасть прямо во время отправки — не теряем забег
      await _hiveService.saveRun(run);
    }
  }

  Future<void> _uploadRun(RunModel run) async {
    await _firebaseService.runsCollection.doc(run.id).set(run.toMap());
    if (run.isValidForRecord) {
      await _maybeUpdateRecord(run);
    }
  }

  Future<void> _maybeUpdateRecord(RunModel run) async {
    final userDocRef = _firebaseService.usersCollection.doc(run.userId);
    final snapshot = await userDocRef.get();
    if (!snapshot.exists || snapshot.data() == null) return;
    final user = UserModel.fromMap(snapshot.data()!);

    final field = switch (run.mode) {
      RunMode.sprint => 'bestSprintSeconds',
      RunMode.snake => 'bestSnakeSeconds',
      RunMode.timed => 'bestTimedSeconds',
    };
    final currentBest = switch (run.mode) {
      RunMode.sprint => user.bestSprintSeconds,
      RunMode.snake => user.bestSnakeSeconds,
      RunMode.timed => user.bestTimedSeconds,
    };

    if (currentBest == null || run.totalTimeSeconds < currentBest) {
      await userDocRef.update({field: run.totalTimeSeconds.toDouble()});
    }
  }

  /// Достаёт из Hive все несинхронизированные забеги и пробует отправить.
  /// Вызывается автоматически при восстановлении сети (см. подписку в
  /// конструкторе), но можно дёрнуть и вручную.
  Future<void> syncOfflineRuns() async {
    if (!await _hasInternet()) return;
    final unsynced = _hiveService.getUnsyncedRuns();
    for (final run in unsynced) {
      try {
        await _uploadRun(run);
        await _hiveService.markSynced(run.id);
      } catch (_) {
        // не получилось — попробуем при следующей синхронизации
      }
    }
  }

  Future<List<RunModel>> getUserRuns(String userId) async {
    try {
      final snapshot = await _firebaseService.runsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();
      final remote = snapshot.docs.map((d) => RunModel.fromMap(d.data())).toList();
      final localOnly =
          _hiveService.getAllRuns().where((r) => r.userId == userId && !r.synced);
      return [...localOnly, ...remote];
    } catch (e) {
      // нет сети — отдаём хотя бы то, что есть локально
      return _hiveService.getAllRuns().where((r) => r.userId == userId).toList();
    }
  }

  /// Последний завершённый забег этого режима — трек для "гонки с собой".
  Future<RunModel?> getLastRunForGhost(String userId, RunMode mode) async {
    try {
      final snapshot = await _firebaseService.runsCollection
          .where('userId', isEqualTo: userId)
          .where('mode', isEqualTo: mode.name)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return RunModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  /// Время друга на этом маршруте/режиме — используется как цель в
  /// "гонке с рекордом друга".
  Future<double?> getFriendBestSeconds(String friendUid, RunMode mode) async {
    final doc = await _firebaseService.usersCollection.doc(friendUid).get();
    if (!doc.exists || doc.data() == null) return null;
    final friend = UserModel.fromMap(doc.data()!);
    return switch (mode) {
      RunMode.sprint => friend.bestSprintSeconds,
      RunMode.snake => friend.bestSnakeSeconds,
      RunMode.timed => friend.bestTimedSeconds,
    };
  }
}
