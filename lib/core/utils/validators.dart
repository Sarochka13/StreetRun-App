/// Простые валидаторы для полей форм (используются как validator в TextFormField).
class Validators {
  Validators._();

  static final RegExp _emailRegExp =
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите email';
    }
    if (!_emailRegExp.hasMatch(value.trim())) {
      return 'Некорректный email';
    }
    return null;
  }

  /// По ТЗ пароль минимум 6 символов.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен быть не короче 6 символов';
    }
    return null;
  }

  static String? nickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите никнейм';
    }
    if (value.trim().length < 2) {
      return 'Никнейм слишком короткий';
    }
    return null;
  }

  /// Возраст опциональный, но если введён — должен быть разумным числом.
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // поле опционально
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 5 || parsed > 120) {
      return 'Введите корректный возраст';
    }
    return null;
  }
}
