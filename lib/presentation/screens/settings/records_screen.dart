import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/utils/formatters.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late Future<Map<String, double?>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final uid = authState is AuthAuthenticated ? authState.user.uid : null;
    _recordsFuture = uid == null
        ? Future.value({'sprint': null, 'snake': null, 'timed': null})
        : context.read<SettingsCubit>().getRecords(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsRecords)),
      body: FutureBuilder<Map<String, double?>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _RecordCard(
                icon: Icons.bolt,
                title: AppStrings.modeSprintTitle,
                seconds: records['sprint'],
              ),
              const SizedBox(height: 12),
              _RecordCard(
                icon: Icons.timeline,
                title: AppStrings.modeSnakeTitle,
                seconds: records['snake'],
              ),
              const SizedBox(height: 12),
              _RecordCard(
                icon: Icons.timer_outlined,
                title: AppStrings.modeTimedTitle,
                seconds: records['timed'],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double? seconds;

  const _RecordCard({required this.icon, required this.title, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.neonBlue.withValues(alpha: 0.15),
          child: Icon(icon, color: AppColors.neonBlue),
        ),
        title: Text(title),
        trailing: Text(
          seconds != null ? Formatters.duration(seconds!.round()) : 'Нет рекорда',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
