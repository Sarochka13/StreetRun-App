import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';
import 'package:streetrun/presentation/screens/auth/email_verification_screen.dart';
import 'package:streetrun/presentation/screens/auth/forgot_password_screen.dart';
import 'package:streetrun/presentation/screens/auth/login_screen.dart';
import 'package:streetrun/presentation/screens/auth/registration_screen.dart';
import 'package:streetrun/presentation/screens/friends/add_friend_screen.dart';
import 'package:streetrun/presentation/screens/friends/friend_profile_screen.dart';
import 'package:streetrun/presentation/screens/friends/friend_requests_screen.dart';
import 'package:streetrun/presentation/screens/friends/friends_list_screen.dart';
import 'package:streetrun/presentation/screens/main_menu/main_menu_screen.dart';
import 'package:streetrun/presentation/screens/onboarding/location_permission_screen.dart';
import 'package:streetrun/presentation/screens/onboarding/terms_screen.dart';
import 'package:streetrun/presentation/screens/run/finish_screen.dart';
import 'package:streetrun/presentation/screens/run/mode_selection_screen.dart';
import 'package:streetrun/presentation/screens/run/run_in_progress_screen.dart';
import 'package:streetrun/presentation/screens/settings/profile_edit_screen.dart';
import 'package:streetrun/presentation/screens/settings/records_screen.dart';
import 'package:streetrun/presentation/screens/settings/settings_screen.dart';
import 'package:streetrun/presentation/screens/settings/terms_readonly_screen.dart';

const _onboardingRoutes = {AppRoutes.onboardingLocation, AppRoutes.onboardingTerms};
const _authRoutes = {AppRoutes.login, AppRoutes.register, AppRoutes.forgotPassword};

/// Собирает GoRouter, завязанный на AuthCubit и SettingsCubit — оба должны
/// быть уже созданы и (для SettingsCubit) загружены к моменту вызова,
/// см. main.dart / app.dart.
GoRouter buildAppRouter({
  required AuthCubit authCubit,
  required SettingsCubit settingsCubit,
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      StreamGroup.merge([authCubit.stream, settingsCubit.stream]),
    ),
    redirect: (context, state) => _redirect(state, authCubit, settingsCubit),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _SplashScreen()),
      GoRoute(
        path: AppRoutes.onboardingLocation,
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingTerms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegistrationScreen()),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: AppRoutes.menu, builder: (context, state) => const MainMenuScreen()),
      GoRoute(
        path: AppRoutes.modeSelection,
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.runInProgress,
        builder: (context, state) => const RunInProgressScreen(),
      ),
      GoRoute(path: AppRoutes.finish, builder: (context, state) => const FinishScreen()),
      GoRoute(path: AppRoutes.friends, builder: (context, state) => const FriendsListScreen()),
      GoRoute(path: AppRoutes.addFriend, builder: (context, state) => const AddFriendScreen()),
      GoRoute(
        path: AppRoutes.friendRequests,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.friendProfile}/:uid',
        builder: (context, state) =>
            FriendProfileScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(path: AppRoutes.records, builder: (context, state) => const RecordsScreen()),
      GoRoute(
        path: AppRoutes.termsReadOnly,
        builder: (context, state) => const TermsReadOnlyScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Страница не найдена: ${state.matchedLocation}')),
    ),
  );
}

String? _redirect(GoRouterState state, AuthCubit authCubit, SettingsCubit settingsCubit) {
  final loc = state.matchedLocation;
  final settingsState = settingsCubit.state;
  final authState = authCubit.state;

  // Настройки ещё не загружены (обычно не должно случаться — см. main.dart,
  // где мы ждём loadInitial() до runApp) — просто ничего не делаем.
  if (!settingsState.isLoaded) return null;

  // 1. Онбординг не пройден -> держим пользователя на экранах онбординга.
  if (!settingsState.onboardingComplete) {
    return _onboardingRoutes.contains(loc) ? null : AppRoutes.onboardingLocation;
  }

  // 2. Firebase Auth ещё не сообщил свой статус -> остаёмся на сплэше.
  if (authState is AuthInitial) {
    return loc == '/' ? null : null;
  }

  // 3. Не залогинен -> пускаем только на экраны авторизации.
  if (authState is AuthUnauthenticated) {
    return _authRoutes.contains(loc) ? null : AppRoutes.login;
  }

  // 4. Залогинен, но почта не подтверждена.
  if (authState is AuthEmailNotVerified) {
    return loc == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }

  // 5. Полностью залогинен — не даём вернуться на экраны онбординга/входа.
  if (authState is AuthAuthenticated) {
    final shouldLeave =
        _authRoutes.contains(loc) || loc == AppRoutes.verifyEmail || loc == '/';
    return shouldLeave ? AppRoutes.menu : null;
  }

  return null;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Стандартный помощник из документации go_router: превращает Stream в
/// Listenable, чтобы GoRouter мог сам перестраивать редирект при каждом
/// новом состоянии Cubit'ов.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Небольшая замена package:async StreamGroup.merge, чтобы не тащить
/// отдельную зависимость ради одной функции.
class StreamGroup {
  static Stream<dynamic> merge(List<Stream<dynamic>> streams) {
    final controller = StreamController<dynamic>.broadcast();
    final subs = <StreamSubscription>[];
    for (final s in streams) {
      subs.add(s.listen(controller.add));
    }
    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };
    return controller.stream;
  }
}
