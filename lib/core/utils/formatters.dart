/// Форматирование чисел/времени для отображения в UI.
class Formatters {
  Formatters._();

  /// 65 -> "01:05", 3725 -> "01:02:05"
  static String duration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// 2.503 -> "2.50 км"
  static String distanceKm(double km) {
    return '${km.toStringAsFixed(2)} км';
  }

  /// Возвращает темп в формате "мин/км", например "5:32 /км".
  /// Если дистанция около нуля — отдаём прочерк, чтобы не делить на 0.
  static String pace(double distanceKm, int totalSeconds) {
    if (distanceKm < 0.01) return '—:—  /км';
    final secPerKm = totalSeconds / distanceKm;
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')} /км';
  }

  /// 452.3 -> "452 ккал"
  static String calories(double kcal) {
    return '${kcal.round()} ккал';
  }
}
