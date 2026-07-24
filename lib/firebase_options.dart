// ЭТО ШАБЛОН. Реальные значения нужно получить из вашего проекта Firebase.
//
// Самый простой способ — установить FlutterFire CLI и один раз выполнить
// в корне проекта:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
// Команда сама создаст такой файл (перезаписав этот) с настоящими ключами
// и заодно положит android/app/google-services.json.
//
// Подробная инструкция — в README.md этого проекта.
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions для web не сконфигурированы — запустите flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions не сконфигурированы для платформы $defaultTargetPlatform — '
          'проект StreetRun пока ориентирован на Android (iOS в перспективе).',
        );
    }
  }

  // ЗАМЕНИТЕ на значения из Project settings -> Your apps -> Android app
  // в консоли Firebase (или получите автоматически через flutterfire configure).

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnkEmmno1EF4v-T05ycr21ptyi6bh9HVU',
    appId: '1:620681691964:android:32aa501f341bbabca0d439',
    messagingSenderId: '620681691964',
    projectId: 'streetrun-app',
    storageBucket: 'streetrun-app.firebasestorage.app',
  );
  // Заполните, когда возьмётесь за iOS-версию.

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCpaNJIFvEhd6j2mG_2Qw6dBbGbfssel44',
    appId: '1:620681691964:ios:d7b238e86bf8bc5aa0d439',
    messagingSenderId: '620681691964',
    projectId: 'streetrun-app',
    storageBucket: 'streetrun-app.firebasestorage.app',
    iosBundleId: 'com.streetrun.streetrun',
  );
}
