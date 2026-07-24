import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:streetrun/data/models/friend_model.dart';
import 'package:streetrun/data/models/user_model.dart';
import 'package:streetrun/data/services/firebase_service.dart';

/// Репозиторий друзей. Заявки в друзья храним в отдельной коллекции
/// `friend_requests`, id документа — `{fromUid}_{toUid}`, так что дубликаты
/// заявок в одну сторону просто невозможны на уровне структуры данных.
class FriendsRepository {
  final AppFirebaseService _firebaseService;

  FriendsRepository(this._firebaseService);

  String get _myUid => _firebaseService.currentUser!.uid;

  String _requestDocId(String fromUid, String toUid) => '${fromUid}_$toUid';

  Future<void> sendFriendRequest(String email) async {
    final query = await _firebaseService.usersCollection
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Пользователь с таким email не найден');
    }

    final target = UserModel.fromMap(query.docs.first.data());
    if (target.uid == _myUid) {
      throw Exception('Нельзя добавить самого себя');
    }

    final docId = _requestDocId(_myUid, target.uid);
    final reverseDocId = _requestDocId(target.uid, _myUid);

    final existing = await _firebaseService.friendRequestsCollection.doc(docId).get();
    final reverseExisting =
        await _firebaseService.friendRequestsCollection.doc(reverseDocId).get();

    final existingStatus = existing.data()?['status'] ?? reverseExisting.data()?['status'];
    if (existingStatus == 'accepted') throw Exception('Вы уже друзья');
    if (existingStatus == 'pending') throw Exception('Заявка уже отправлена');

    await _firebaseService.friendRequestsCollection.doc(docId).set({
      'fromUid': _myUid,
      'toUid': target.uid,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> acceptRequest(String fromUid) async {
    final docId = _requestDocId(fromUid, _myUid);
    await _firebaseService.friendRequestsCollection.doc(docId).update({'status': 'accepted'});
  }

  Future<void> rejectRequest(String fromUid) async {
    final docId = _requestDocId(fromUid, _myUid);
    await _firebaseService.friendRequestsCollection.doc(docId).update({'status': 'rejected'});
  }

  Future<List<FriendModel>> getIncomingRequests() async {
    final snapshot = await _firebaseService.friendRequestsCollection
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'pending')
        .get();

    final requests = <FriendModel>[];
    for (final doc in snapshot.docs) {
      final fromUid = doc.data()['fromUid'] as String;
      final userDoc = await _firebaseService.usersCollection.doc(fromUid).get();
      if (!userDoc.exists || userDoc.data() == null) continue;
      final u = UserModel.fromMap(userDoc.data()!);
      requests.add(FriendModel(
        uid: u.uid,
        nickname: u.nickname,
        avatarUrl: u.avatarUrl,
        isOnline: u.isOnline,
        lastOnline: u.lastOnline,
        status: FriendStatus.pending,
        isIncoming: true,
      ));
    }
    return requests;
  }

  Future<List<FriendModel>> getFriendsList() async {
    final asSender = await _firebaseService.friendRequestsCollection
        .where('fromUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'accepted')
        .get();
    final asReceiver = await _firebaseService.friendRequestsCollection
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final otherUids = <String>{
      ...asSender.docs.map((d) => d.data()['toUid'] as String),
      ...asReceiver.docs.map((d) => d.data()['fromUid'] as String),
    };

    final friends = <FriendModel>[];
    for (final uid in otherUids) {
      final userDoc = await _firebaseService.usersCollection.doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) continue;
      final u = UserModel.fromMap(userDoc.data()!);
      friends.add(FriendModel(
        uid: u.uid,
        nickname: u.nickname,
        avatarUrl: u.avatarUrl,
        isOnline: u.isOnline,
        lastOnline: u.lastOnline,
        status: FriendStatus.accepted,
      ));
    }

    // По ТЗ: онлайн сверху, дальше по алфавиту.
    friends.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      return a.nickname.toLowerCase().compareTo(b.nickname.toLowerCase());
    });
    return friends;
  }

  /// Публичный профиль друга — без рекордов, как требует ТЗ.
  Future<FriendModel> getFriendProfile(String uid) async {
    final doc = await _firebaseService.usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Профиль не найден');
    }
    final u = UserModel.fromMap(doc.data()!);
    return FriendModel(
      uid: u.uid,
      nickname: u.nickname,
      avatarUrl: u.avatarUrl,
      isOnline: u.isOnline,
      lastOnline: u.lastOnline,
      gender: u.gender,
      age: u.age,
      registrationDate: u.registrationDate,
    );
  }
}
