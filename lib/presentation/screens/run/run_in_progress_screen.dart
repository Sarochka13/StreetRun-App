import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/utils/formatters.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/data/models/run_model.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/friends/friends_cubit.dart';
import 'package:streetrun/presentation/bloc/run/run_cubit.dart';

class RunInProgressScreen extends StatefulWidget {
  const RunInProgressScreen({super.key});

  @override
  State<RunInProgressScreen> createState() => _RunInProgressScreenState();
}

class _RunInProgressScreenState extends State<RunInProgressScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<String>? _messagesSub;

  @override
  void initState() {
    super.initState();
    // Голосовые/анти-чит сообщения дублируем снэкбаром — не все услышат TTS
    // в наушниках или на шумной улице.
    _messagesSub = context.read<RunCubit>().messages.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }

  void _pickFriendForRace() {
    final runCubit = context.read<RunCubit>();
    final friendsCubit = context.read<FriendsCubit>();
    friendsCubit.loadAll();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: BlocBuilder<FriendsCubit, FriendsState>(
            bloc: friendsCubit,
            builder: (context, state) {
              if (state is FriendsLoading) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final friends = state is FriendsLoaded ? state.friends : const [];
              if (friends.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Пока нет друзей, с кем можно посоревноваться.'),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: friends
                    .map((f) => ListTile(
                          leading: UserAvatar(avatarUrl: f.avatarUrl, radius: 18),
                          title: Text(f.nickname),
                          onTap: () {
                            Navigator.of(context).pop();
                            runCubit.enableFriendRace(f.uid);
                          },
                        ))
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RunCubit, RunState>(
      listener: (context, state) {
        if (state is RunActive && state.track.isNotEmpty) {
          _mapController.move(state.track.last, 16.5);
        }
        if (state is RunFinished) {
          context.go(AppRoutes.finish);
        }
      },
      builder: (context, state) {
        if (state is RunPreparing) return _buildPreparing(context, state);
        if (state is RunActive) return _buildActive(context, state);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildPreparing(BuildContext context, RunPreparing state) {
    final authState = context.watch<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : null;
    final hasRaceTarget = state.ghostTrack != null || state.friendTargetSeconds != null;

    return Scaffold(
      appBar: AppBar(title: Text(state.route.mode.label)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: state.route.startPoint, initialZoom: 15.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.streetrun.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: state.route.startPoint,
                  width: 34,
                  height: 34,
                  child: const Icon(Icons.my_location, color: AppColors.neonBlue),
                ),
                ...state.route.checkpoints.map(
                  (c) => Marker(
                    point: c.position,
                    width: 30,
                    height: 30,
                    child: const Icon(Icons.flag, color: Colors.orangeAccent),
                  ),
                ),
              ]),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Дистанция: ${Formatters.distanceKm(state.route.plannedDistanceKm)}'),
                    if (state.ghostTotalSeconds != null)
                      Text('Ваш прошлый результат: ${Formatters.duration(state.ghostTotalSeconds!)}'),
                    if (state.friendTargetSeconds != null)
                      Text('Цель — время друга: ${Formatters.duration(state.friendTargetSeconds!.round())}'),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                if (!hasRaceTarget) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.replay),
                          label: const Text('С собой'),
                          onPressed: userId == null
                              ? null
                              : () => context.read<RunCubit>().enableGhostRace(userId),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.people),
                          label: const Text('С другом'),
                          onPressed: _pickFriendForRace,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                CustomButton(
                  text: 'СТАРТ',
                  onPressed: userId == null
                      ? null
                      : () => context.read<RunCubit>().startRun(userId: userId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActive(BuildContext context, RunActive state) {
    final center = state.track.isNotEmpty ? state.track.last : state.route.startPoint;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: center, initialZoom: 16.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.streetrun.app',
              ),
              PolylineLayer(polylines: [
                if (state.ghostTrack != null)
                  Polyline(points: state.ghostTrack!, color: Colors.grey, strokeWidth: 3, isDotted: true),
                Polyline(points: state.track, color: AppColors.neonBlue, strokeWidth: 5),
              ]),
              MarkerLayer(markers: [
                ...state.route.checkpoints.asMap().entries.map((entry) => Marker(
                      point: entry.value.position,
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.flag,
                        color: entry.key < state.nextCheckpointIndex
                            ? AppColors.success
                            : Colors.orangeAccent,
                      ),
                    )),
                if (state.track.isNotEmpty)
                  Marker(
                    point: state.track.last,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration:
                          const BoxDecoration(color: AppColors.neonBlue, shape: BoxShape.circle),
                    ),
                  ),
              ]),
            ],
          ),
          Positioned(left: 16, right: 16, top: 16, child: _StatsCard(state: state)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => context.read<RunCubit>().stopRun(),
                child: const Text('СТОП', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final RunActive state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(label: 'Время', value: Formatters.duration(state.elapsedSeconds)),
                _Stat(label: 'Дистанция', value: Formatters.distanceKm(state.distanceKm)),
                _Stat(label: 'Темп', value: Formatters.pace(state.distanceKm, state.elapsedSeconds)),
              ],
            ),
            if (state.totalCheckpoints > 1) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: state.nextCheckpointIndex / state.totalCheckpoints,
                backgroundColor: AppColors.darkSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text('Чекпоинты: ${state.nextCheckpointIndex}/${state.totalCheckpoints}'),
            ],
            if (state.violationsCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Предупреждений по скорости: ${state.violationsCount}/3',
                style: const TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
