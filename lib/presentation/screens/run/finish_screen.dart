import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/utils/formatters.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/data/models/run_model.dart';
import 'package:streetrun/presentation/bloc/run/run_cubit.dart';

class FinishScreen extends StatelessWidget {
  const FinishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RunCubit>().state;
    if (state is! RunFinished) {
      // Например, экран открыли напрямую без активного забега — ведём в меню.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.menu);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final run = state.result;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.emoji_events, size: 72, color: AppColors.neonBlue),
              const SizedBox(height: 12),
              Text(
                AppStrings.finishTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(run.mode.label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ResultTile(label: 'Время', value: Formatters.duration(run.totalTimeSeconds)),
                          _ResultTile(label: 'Дистанция', value: Formatters.distanceKm(run.distanceKm)),
                          _ResultTile(label: 'Калории', value: Formatters.calories(run.caloriesBurned)),
                        ],
                      ),
                      if (!run.isValidForRecord) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Обнаружены резкие ускорения — этот забег не пойдёт в рекорды.',
                            style: TextStyle(color: AppColors.warning),
                          ),
                        ),
                      ],
                      if (state.comparisonSeconds != null) ...[
                        const SizedBox(height: 20),
                        _ComparisonCard(
                          label: state.comparisonLabel ?? 'Сравнение',
                          targetSeconds: state.comparisonSeconds!,
                          actualSeconds: run.totalTimeSeconds,
                        ),
                      ],
                      if (run.mode == RunMode.snake &&
                          run.checkpointTimes != null &&
                          run.checkpointTimes!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Время по чекпоинтам',
                              style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        ...run.checkpointTimes!.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Чекпоинт ${e.key + 1}'),
                                    Text(Formatters.duration(e.value)),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
              CustomButton(
                text: AppStrings.finishBackToMenu,
                onPressed: () {
                  context.read<RunCubit>().reset();
                  context.go(AppRoutes.menu);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  const _ResultTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String label;
  final double targetSeconds;
  final int actualSeconds;

  const _ComparisonCard({
    required this.label,
    required this.targetSeconds,
    required this.actualSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final diff = actualSeconds - targetSeconds;
    final beat = diff <= 0;
    final diffText = Formatters.duration(diff.abs().round());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              beat ? 'Быстрее на $diffText 🎉' : 'Медленнее на $diffText',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: beat ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
