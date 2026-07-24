/// Статус дружбы между двумя пользователями.
enum FriendStatus { pending, accepted, rejected }

/// Модель друга — используется и в списке друзей, и в списке заявок,
/// и в публичном профиле друга. Не всё поле заполнено всегда: в списке
/// заявок, например, не нужны рекорды (их и по ТЗ показывать нельзя).
class FriendModel {
  final String uid;
  final String nickname;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastOnline;
  final FriendStatus status;

  /// true, если заявку прислали НАМ (актуально для экрана заявок).
  final bool isIncoming;

  // публичные поля профиля (для FriendProfileScreen)
  final String? gender;
  final int? age;
  final DateTime? registrationDate;

  const FriendModel({
    required this.uid,
    required this.nickname,
    this.avatarUrl,
    this.isOnline = false,
    this.lastOnline,
    this.status = FriendStatus.accepted,
    this.isIncoming = false,
    this.gender,
    this.age,
    this.registrationDate,
  });
}
