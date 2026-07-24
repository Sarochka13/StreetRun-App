import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:streetrun/app.dart';
import 'package:streetrun/data/repositories/auth_repository.dart';
import 'package:streetrun/data/repositories/friends_repository.dart';
import 'package:streetrun/data/repositories/run_repository.dart';
import 'package:streetrun/data/repositories/settings_repository.dart';
import 'package:streetrun/data/services/cloudinary_service.dart';
import 'package:streetrun/data/services/firebase_service.dart';
import 'package:streetrun/data/services/gps_service.dart';
import 'package:streetrun/data/services/hive_service.dart';
import 'package:streetrun/data/services/tts_service.dart';
import 'package:streetrun/firebase_options.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/friends/friends_cubit.dart';
import 'package:streetrun/presentation/bloc/run/run_cubit.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';

Future<void> main() async {
  // Всё, что нужно до первого кадра, делаем здесь и ждём — это спасает от
  // "мигания" неправильным экраном при старте (см. app_router.dart).
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final hiveService = HiveService();
  await hiveService.init();

  // ---- сервисы ----
  final firebaseService = AppFirebaseService();
  final cloudinaryService = CloudinaryService();
  final gpsService = GpsService();
  final ttsService = TtsService();

  // ---- репозитории ----
  final authRepository = AuthRepository(firebaseService);
  final runRepository = RunRepository(firebaseService, hiveService);
  final friendsRepository = FriendsRepository(firebaseService);
  final settingsRepository = SettingsRepository(firebaseService, cloudinaryService);

  // ---- cubit'ы ----
  final settingsCubit = SettingsCubit(settingsRepository);
  await settingsCubit.loadInitial(); // важно дождаться до runApp, см. комментарий выше

  final authCubit = AuthCubit(authRepository);
  final runCubit = RunCubit(gpsService, ttsService, runRepository);
  final friendsCubit = FriendsCubit(friendsRepository);

  runApp(App(
    authCubit: authCubit,
    runCubit: runCubit,
    friendsCubit: friendsCubit,
    settingsCubit: settingsCubit,
  ));
}
