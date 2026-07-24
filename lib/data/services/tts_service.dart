import 'package:flutter_tts/flutter_tts.dart';

/// Голосовой помощник во время забега. Настройки (язык, скорость, тон)
/// заданы по ТЗ и не меняются пользователем.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('ru-RU');
    await _tts.setSpeechRate(0.9);
    await _tts.setPitch(1.2);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    try {
      await _ensureInit();
      await _tts.stop(); // не даём фразам накладываться друг на друга
      await _tts.speak(text);
    } catch (_) {
      // Голос — не критичная функция: если TTS недоступен на устройстве,
      // забег всё равно должен продолжать работать молча.
    }
  }

  Future<void> stop() => _tts.stop();
}
