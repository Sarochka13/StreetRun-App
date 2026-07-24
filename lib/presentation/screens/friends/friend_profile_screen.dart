import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/data/models/friend_model.dart';
import 'package:streetrun/presentation/bloc/friends/friends_cubit.dart';

class FriendProfileScreen extends StatefulWidget {
  final String uid;
  const FriendProfileScreen({super.key, required this.uid});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late Future<FriendModel> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = context.read<FriendsCubit>().loadFriendProfile(widget.uid);
  }

  String _genderLabel(String? gender) {
    switch (gender) {
      case 'male':
        return 'Мужской';
      case 'female':
        return 'Женский';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: FutureBuilder<FriendModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Не удалось загрузить профиль'));
          }

          final friend = snapshot.data!;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  UserAvatar(avatarUrl: friend.avatarUrl, radius: 48, isOnline: friend.isOnline),
                  const SizedBox(height: 16),
                  Text(friend.nickname, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    friend.isOnline ? 'В сети' : 'Не в сети',
                    style: TextStyle(color: friend.isOnline ? Colors.green : Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(label: 'Пол', value: _genderLabel(friend.gender)),
                          _InfoRow(label: 'Возраст', value: friend.age?.toString() ?? '—'),
                          _InfoRow(
                            label: 'В приложении с',
                            value: friend.registrationDate != null
                                ? DateFormat('dd.MM.yyyy').format(friend.registrationDate!)
                                : '—',
                          ),
                          _InfoRow(
                            label: 'Последний раз в сети',
                            value: friend.lastOnline != null
                                ? DateFormat('dd.MM.yyyy HH:mm').format(friend.lastOnline!)
                                : '—',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
