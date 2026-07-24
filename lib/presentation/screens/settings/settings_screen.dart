import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text(AppStrings.settingsTheme),
                subtitle: Text(state.themeMode == ThemeMode.dark ? 'Тёмная' : 'Светлая'),
                secondary: Icon(state.themeMode == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode),
                value: state.themeMode == ThemeMode.dark,
                onChanged: (_) => context.read<SettingsCubit>().toggleTheme(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text(AppStrings.settingsPersonalization),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.profileEdit),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text(AppStrings.settingsRecords),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.records),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text(AppStrings.settingsTerms),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.termsReadOnly),
              ),
            ],
          );
        },
      ),
    );
  }
}
