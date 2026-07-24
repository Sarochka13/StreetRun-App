import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/presentation/bloc/friends/friends_cubit.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заявки в друзья')),
      body: BlocBuilder<FriendsCubit, FriendsState>(
        builder: (context, state) {
          if (state is FriendsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = state is FriendsLoaded ? state.incomingRequests : const [];
          if (requests.isEmpty) {
            return const Center(child: Text('Новых заявок нет'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final r = requests[index];
              return ListTile(
                leading: UserAvatar(avatarUrl: r.avatarUrl),
                title: Text(r.nickname),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => context.read<FriendsCubit>().acceptRequest(r.uid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: () => context.read<FriendsCubit>().rejectRequest(r.uid),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
