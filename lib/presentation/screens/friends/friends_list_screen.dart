import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/presentation/bloc/friends/friends_cubit.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FriendsCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.friendsTitle)),
      body: RefreshIndicator(
        onRefresh: () => context.read<FriendsCubit>().loadAll(),
        child: BlocBuilder<FriendsCubit, FriendsState>(
          builder: (context, state) {
            if (state is FriendsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FriendsError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text(state.message, textAlign: TextAlign.center)),
                ],
              );
            }

            final loaded = state as FriendsLoaded;

            return ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (loaded.incomingRequests.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1),
                    title: Text('${AppStrings.acceptRequestButton} (${loaded.incomingRequests.length})'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.friendRequests),
                  ),
                if (loaded.friends.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: Text('Пока нет друзей — добавьте по email')),
                  )
                else
                  ...loaded.friends.map(
                    (f) => ListTile(
                      leading: UserAvatar(avatarUrl: f.avatarUrl, isOnline: f.isOnline),
                      title: Text(f.nickname),
                      subtitle: Text(f.isOnline ? 'В сети' : 'Не в сети'),
                      onTap: () => context.push('${AppRoutes.friendProfile}/${f.uid}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addFriend),
        icon: const Icon(Icons.person_add),
        label: const Text(AppStrings.addFriendButton),
      ),
    );
  }
}
