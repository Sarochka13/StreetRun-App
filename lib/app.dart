import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/theme/app_theme.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/friends/friends_cubit.dart';
import 'package:streetrun/presentation/bloc/run/run_cubit.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';
import 'package:streetrun/presentation/navigation/app_router.dart';

/// Корневой виджет. Все Cubit'ы уже созданы в main.dart (некоторые —
/// после обязательных await'ов вроде SettingsCubit.loadInitial()) и просто
/// прокидываются сюда через BlocProvider.value.
class App extends StatefulWidget {
  final AuthCubit authCubit;
  final RunCubit runCubit;
  final FriendsCubit friendsCubit;
  final SettingsCubit settingsCubit;

  const App({
    super.key,
    required this.authCubit,
    required this.runCubit,
    required this.friendsCubit,
    required this.settingsCubit,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildAppRouter(authCubit: widget.authCubit, settingsCubit: widget.settingsCubit);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Статус "онлайн" для друзей обновляем не только при явном логауте,
    // но и при сворачивании/разворачивании приложения.
    if (state == AppLifecycleState.resumed) {
      widget.authCubit.updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused) {
      widget.authCubit.updateOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: widget.authCubit),
        BlocProvider<RunCubit>.value(value: widget.runCubit),
        BlocProvider<FriendsCubit>.value(value: widget.friendsCubit),
        BlocProvider<SettingsCubit>.value(value: widget.settingsCubit),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) => previous.themeMode != current.themeMode,
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
