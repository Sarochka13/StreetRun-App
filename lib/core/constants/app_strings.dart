/// Все текстовые строки интерфейса в одном месте, чтобы не размазывать
/// текст по виджетам и было проще один раз всё поправить/перевести.
class AppStrings {
  AppStrings._();

  static const String appName = 'StreetRun';

  // ---- Онбординг ----
  static const String locationPermissionTitle = 'Нужен доступ к геолокации';
  static const String locationPermissionBody =
      'StreetRun использует GPS, чтобы записывать ваш маршрут, считать '
      'дистанцию и калории. Без доступа к геолокации забег не получится '
      'записать.';
  static const String locationPermissionButton = 'Разрешить доступ';
  static const String termsTitle = 'Пользовательское соглашение';
  static const String termsAcceptCheckbox = 'Я принимаю условия соглашения';
  static const String termsContinueButton = 'Продолжить';

  // ---- Авторизация ----
  static const String loginTitle = 'Вход';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Пароль';
  static const String loginButton = 'Войти';
  static const String forgotPasswordLink = 'Забыли пароль?';
  static const String noAccountLink = 'Нет аккаунта? Зарегистрироваться';
  static const String registerTitle = 'Регистрация';
  static const String nicknameLabel = 'Никнейм';
  static const String genderLabel = 'Пол';
  static const String ageLabel = 'Возраст';
  static const String registerButton = 'Зарегистрироваться';
  static const String verifyEmailButtonConfirmed = 'Я подтвердил, войти';
  static const String verifyEmailButtonResend = 'Отправить письмо повторно';
  static const String forgotPasswordButton = 'Отправить ссылку для сброса пароля';

  // ---- Главное меню ----
  static const String menuStart = 'НАЧАТЬ';
  static const String menuFriends = 'ДРУЗЬЯ';
  static const String menuSettings = 'НАСТРОЙКИ';
  static const String menuLogout = 'ВЫЙТИ';

  // ---- Режимы забега ----
  static const String modeSprintTitle = 'Спринт';
  static const String modeSprintDesc = 'Точка А → точка Б (500–3000 м)';
  static const String modeSnakeTitle = 'Змейка';
  static const String modeSnakeDesc = '5 чекпоинтов в радиусе 1 км';
  static const String modeTimedTitle = 'На время';
  static const String modeTimedDesc = 'Круг по маршруту (1–2 км)';

  // ---- Голосовые подсказки (TTS) ----
  static const String ttsStart = 'Внимание! Маршрут активирован. Погнали!';
  static String ttsCheckpoint(int remaining) =>
      'Чекпоинт взят! Осталось еще $remaining точек.';
  static const String ttsSlowDown = 'Эй, ты сбавил скорость! Соперник догоняет!';
  static const String ttsSpeedUp = 'Хороший темп! Так держать!';
  static const String ttsHalfway = 'Ты на экваторе! Половина позади!';
  static const String ttsFinish = 'ФИНИШ! Ты справился! Отличный результат!';
  static const String ttsAntiCheatWarning =
      'Слишком быстро для бега или ходьбы. Похоже на транспорт — забег может не '
      'засчитаться в рекорды.';

  // ---- Финиш ----
  static const String finishTitle = 'ПОЗДРАВЛЯЕМ';
  static const String finishBackToMenu = 'В ГЛАВНОЕ МЕНЮ';

  // ---- Друзья ----
  static const String friendsTitle = 'Друзья';
  static const String addFriendButton = 'ДОБАВИТЬ ДРУГА';
  static const String acceptRequestButton = 'ПРИНЯТЬ ЗАПРОС';
  static const String addFriendHint = 'Введите email друга';

  // ---- Настройки ----
  static const String settingsTitle = 'Настройки';
  static const String settingsTheme = 'Тема';
  static const String settingsPersonalization = 'Персонализация';
  static const String settingsRecords = 'Рекорды';
  static const String settingsTerms = 'Пользовательское соглашение';

  static const String termsFullText = '''
Используя StreetRun, вы соглашаетесь с тем, что:

1. Приложение записывает данные геолокации во время забега для расчёта дистанции, темпа и калорий.
2. Ваш никнейм, аватарка и статус "онлайн" видны вашим друзьям в приложении.
3. Результаты забегов и рекорды сохраняются в вашем профиле и могут сравниваться с результатами друзей.
4. Приложение не заменяет консультацию врача — перед началом тренировок при наличии противопоказаний проконсультируйтесь со специалистом.
5. Вы можете удалить аккаунт и связанные с ним данные в любой момент, обратившись в поддержку.
''';
}
