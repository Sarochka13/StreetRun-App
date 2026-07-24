import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/data/models/friend_model.dart';
import 'package:streetrun/data/repositories/friends_repository.dart';

sealed class FriendsState extends Equatable {
  const FriendsState();
  @override
  List<Object?> get props => [];
}

class FriendsLoading extends FriendsState {}

class FriendsLoaded extends FriendsState {
  final List<FriendModel> friends;
  final List<FriendModel> incomingRequests;

  const FriendsLoaded({required this.friends, required this.incomingRequests});

  @override
  List<Object?> get props => [friends, incomingRequests];
}

class FriendsError extends FriendsState {
  final String message;
  const FriendsError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cubit списка друзей и входящих заявок. Действия (принять/отклонить/
/// добавить) просто перезагружают весь список — для такого небольшого
/// объёма данных это проще и надёжнее точечных обновлений состояния.
class FriendsCubit extends Cubit<FriendsState> {
  final FriendsRepository _friendsRepository;

  FriendsCubit(this._friendsRepository) : super(FriendsLoading());

  Future<void> loadAll() async {
    emit(FriendsLoading());
    try {
      final friends = await _friendsRepository.getFriendsList();
      final requests = await _friendsRepository.getIncomingRequests();
      emit(FriendsLoaded(friends: friends, incomingRequests: requests));
    } catch (e) {
      emit(FriendsError('Не удалось загрузить друзей: $e'));
    }
  }

  /// Пробрасывает исключение репозитория дальше — экран сам покажет текст ошибки.
  Future<void> sendRequest(String email) async {
    await _friendsRepository.sendFriendRequest(email);
    await loadAll();
  }

  Future<void> acceptRequest(String fromUid) async {
    await _friendsRepository.acceptRequest(fromUid);
    await loadAll();
  }

  Future<void> rejectRequest(String fromUid) async {
    await _friendsRepository.rejectRequest(fromUid);
    await loadAll();
  }

  Future<FriendModel> loadFriendProfile(String uid) {
    return _friendsRepository.getFriendProfile(uid);
  }
}
