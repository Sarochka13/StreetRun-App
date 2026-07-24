import 'package:hive_flutter/hive_flutter.dart';
import 'package:streetrun/data/models/run_model.dart';

/// Работа с локальным хранилищем Hive — используется как офлайн-буфер
/// для забегов, когда нет интернета (см. RunRepository).
class HiveService {
  static const String runsBoxName = 'runs_box';

  late Box<RunModel> _runsBox;

  /// Вызывается один раз при старте приложения, до runApp().
  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RunModelAdapter());
    }
    _runsBox = await Hive.openBox<RunModel>(runsBoxName);
  }

  Future<void> saveRun(RunModel run) async {
    await _runsBox.put(run.id, run);
  }

  List<RunModel> getAllRuns() => _runsBox.values.toList();

  /// Забеги, которые ещё не улетели в Firestore.
  List<RunModel> getUnsyncedRuns() =>
      _runsBox.values.where((r) => !r.synced).toList();

  Future<void> markSynced(String runId) async {
    final run = _runsBox.get(runId);
    if (run != null) {
      await _runsBox.put(runId, run.copyWith(synced: true));
    }
  }

  Future<void> deleteRun(String runId) async {
    await _runsBox.delete(runId);
  }
}
