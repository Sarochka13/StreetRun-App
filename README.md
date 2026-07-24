# StreetRun

Приложение для бега/ходьбы по городу с записью GPS-трека, чекпоинтами,
друзьями и голосовыми подсказками. Flutter + Firebase (Auth/Firestore) +
Cloudinary (аватарки) + OpenStreetMap.

## Структура проекта

```
lib/
├── main.dart              # инициализация Firebase/Hive, сборка зависимостей
├── app.dart                # MaterialApp.router, темы, provider'ы
├── firebase_options.dart   # ШАБЛОН — см. шаг 2 ниже
├── core/                   # константы, тема, валидаторы, форматтеры, общие виджеты
├── data/
│   ├── models/              # UserModel, RunModel (+Hive), FriendModel, RouteModel
│   ├── services/             # обёртки над Firebase/Cloudinary/geolocator/Hive/TTS
│   └── repositories/         # бизнес-логика поверх сервисов
└── presentation/
    ├── bloc/                 # AuthCubit, RunCubit, FriendsCubit, SettingsCubit
    ├── screens/               # все экраны по папкам (onboarding/auth/run/friends/settings)
    └── navigation/            # go_router + редиректы по auth-статусу

android/app/google-services.json   # ШАБЛОН — см. шаг 2
firestore.rules                     # правила безопасности Firestore
```

## Что уже сделано, а что нужно донастроить

Весь код приложения — экраны, BLoC/Cubit, репозитории, сервисы, модели —
готов и рабочий. Два места принципиально нельзя заполнить заранее, так как
для них нужен доступ к вашим личным аккаунтам:

1. **Firebase** (`lib/firebase_options.dart` и `android/app/google-services.json`)
   — сейчас там шаблоны с фейковыми значениями.
2. **Cloudinary** (`lib/data/services/cloudinary_service.dart`) — там нужно
   подставить ваш `cloudName` и `uploadPreset`.

Ниже — пошагово, как всё это настроить.

## Шаг 1. Установка зависимостей

```bash
flutter pub get
```

Если в проекте ещё нет папок `android/`/`ios/` (например, вы просто
скопировали содержимое `lib/` в пустой каталог) — сначала выполните:

```bash
flutter create --org com.streetrun --project-name streetrun .
```

Это сгенерирует стандартные платформенные папки, ничего не трогая в `lib/`
(на вопрос о перезаписи `lib/main.dart` ответьте "нет" — свой мы уже
написали).

## Шаг 2. Настройка Firebase

1. Зайдите в [Firebase Console](https://console.firebase.google.com/) и
   создайте новый проект (например, `streetrun-app`).
2. В проекте включите:
   - **Authentication** → Sign-in method → **Email/Password** (включить).
   - **Firestore Database** → создать базу (можно в тестовом режиме, но
     потом обязательно примените правила из `firestore.rules`, см. ниже).
3. Самый простой способ прописать конфиг в проект — через FlutterFire CLI:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Команда попросит выбрать Firebase-проект и платформы (выберите хотя бы
   Android) и сама перезапишет `lib/firebase_options.dart` настоящими
   значениями, а также положит правильный `android/app/google-services.json`.

   Если предпочитаете вручную: добавьте Android-приложение в консоли
   Firebase (пакет — `com.streetrun.app`, либо ваш, если меняли при
   `flutter create`), скачайте `google-services.json` и замените им файл
   `android/app/google-services.json`, а значения `apiKey`/`appId`/
   `messagingSenderId`/`projectId`/`storageBucket` перенесите в
   `lib/firebase_options.dart`.
4. В `android/build.gradle` (уровень проекта) добавьте в `dependencies`
   classpath для Google Services (если его нет после `flutter create`):

   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.2'
   }
   ```

   А в `android/app/build.gradle` в самом низу файла:

   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
5. Разрешения для фоновой геолокации уже прописаны в
   `android/app/src/main/AndroidManifest.xml` из этого проекта. Если у вас
   уже был свой `AndroidManifest.xml` (после `flutter create`) — перенесите
   в него блок `<uses-permission>` и `<meta-data android:name="flutterEmbedding">`
   из нашего файла.
6. Примените правила безопасности Firestore — самый простой способ:
   скопируйте содержимое `firestore.rules` в Firebase Console → Firestore
   Database → Rules → вставить → Publish. (Либо через Firebase CLI:
   `firebase deploy --only firestore:rules`, если у вас настроен проект.)

## Шаг 3. Настройка Cloudinary (аватарки)

1. Зарегистрируйтесь на [cloudinary.com](https://cloudinary.com) (бесплатного
   тарифа достаточно).
2. В Dashboard скопируйте **Cloud name**.
3. Settings → Upload → Upload presets → Add upload preset → Signing mode:
   **Unsigned** → сохраните, скопируйте имя пресета.
4. Откройте `lib/data/services/cloudinary_service.dart` и замените:

   ```dart
   static const String cloudName = 'YOUR_CLOUD_NAME';
   static const String uploadPreset = 'streetrun_avatars';
   ```

   на свои значения.

## Шаг 4. Проверка кода и запуск

```bash
flutter analyze
flutter run
```

`flutter analyze` стоит прогнать в первую очередь — код написан вручную (без
доступа к `pub.dev` в среде, где он готовился), так что мелкие несостыковки
по версиям пакетов возможны, особенно если ваш Flutter SDK заметно новее
версий пакетов из `pubspec.yaml`. Обычно такие правки точечные (переименование
параметра и т.п.).

Если меняете поля `RunModel` (`lib/data/models/run_model.dart`) — Hive-адаптер
в `run_model.g.dart` написан вручную по образцу генератора. После изменения
модели либо поправьте адаптер руками, либо удалите `run_model.g.dart` и
выполните:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Заметки о реализации (на случай вопросов на защите)

- **Маршруты** (`RouteModel`) генерируются на устройстве от текущей
  геопозиции (см. `GpsService.generateRoute`) — отдельного бэкенда
  маршрутов в ТЗ не было, поэтому точки строятся геометрически (азимут +
  расстояние от старта).
- **Античит**: скорость выше 15 км/ч дольше 30 секунд подряд — один
  "эпизод"; больше 3 эпизодов за забег — `isValidForRecord = false`, и
  результат не идёт в рекорды (но сам забег сохраняется).
- **Калории**: MET = 8.0 при средней скорости ≥ 6.5 км/ч (бег), иначе
  MET = 3.5 (ходьба) — порог не был явно задан в ТЗ, выбран как разумная
  граница темпа. Вес — константа 70 кг, как и указано в задании.
- **Голосовые подсказки "ускорение"**: точный текст в ТЗ был задан только
  для события "замедление" — для симметрии добавлена похожая по духу фраза
  на ускорение ("Хороший темп! Так держать!").
- **Офлайн-режим**: если при завершении забега нет интернета — забег
  уходит в Hive. `RunRepository` сам подписан на `connectivity_plus` и
  запускает синхронизацию с Firestore, как только сеть появляется —
  ничего дополнительно вызывать не нужно.
