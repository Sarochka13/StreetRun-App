import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (user != null) ...[
                UserAvatar(avatarUrl: user.avatarUrl, radius: 36),
                const SizedBox(height: 12),
                Text(user.nickname, style: Theme.of(context).textTheme.titleLarge),
              ],
              const Spacer(),
              _MenuButton(
                icon: Icons.directions_run,
                label: AppStrings.menuStart,
                highlighted: true,
                onTap: () => context.push(AppRoutes.modeSelection),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.people_alt_outlined,
                label: AppStrings.menuFriends,
                onTap: () => context.push(AppRoutes.friends),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.settings_outlined,
                label: AppStrings.menuSettings,
                onTap: () => context.push(AppRoutes.settings),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.logout,
                label: AppStrings.menuLogout,
                onTap: () => context.read<AuthCubit>().logout(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.neonBlue : AppColors.lightAccentBlue;

    return Material(
      color: highlighted ? accent : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: highlighted ? Colors.black : accent, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: highlighted ? Colors.black : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
