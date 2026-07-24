import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/data/models/run_model.dart';
import 'package:streetrun/presentation/bloc/run/run_cubit.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool _loading = false;

  Future<void> _selectMode(RunMode mode) async {
    setState(() => _loading = true);
    try {
      final route = await context.read<RunCubit>().generateRoute(mode);
      if (!mounted) return;
      context.read<RunCubit>().prepareRun(route);
      context.push(AppRoutes.runInProgress);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выбор режима')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _ModeCard(
                      icon: Icons.bolt,
                      title: AppStrings.modeSprintTitle,
                      description: AppStrings.modeSprintDesc,
                      onTap: () => _selectMode(RunMode.sprint),
                    ),
                    const SizedBox(height: 16),
                    _ModeCard(
                      icon: Icons.timeline,
                      title: AppStrings.modeSnakeTitle,
                      description: AppStrings.modeSnakeDesc,
                      onTap: () => _selectMode(RunMode.snake),
                    ),
                    const SizedBox(height: 16),
                    _ModeCard(
                      icon: Icons.timer_outlined,
                      title: AppStrings.modeTimedTitle,
                      description: AppStrings.modeTimedDesc,
                      onTap: () => _selectMode(RunMode.timed),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.neonBlue : AppColors.lightAccentBlue;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(radius: 26, backgroundColor: accent.withValues(alpha: 0.15), child: Icon(icon, color: accent)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
