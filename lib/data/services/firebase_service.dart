import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис — тонкая обёртка над Firebase SDK. Репозитории берут отсюда
/// готовые инстансы Auth/Firestore и уже сами строят бизнес-логику поверх.
class AppFirebaseService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AppFirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<UserCredential> signUp({required String email, required String password}) {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn({required String email, required String password}) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => auth.signOut();

  Future<void> sendEmailVerification() async {
    await auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return auth.sendPasswordResetEmail(email: email);
  }

  /// Firebase кэширует статус верификации почты — чтобы узнать актуальный,
  /// нужно принудительно перезапросить пользователя с сервера.
  Future<bool> reloadAndCheckEmailVerified() async {
    await auth.currentUser?.reload();
    return auth.currentUser?.emailVerified ?? false;
  }

  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get runsCollection =>
      firestore.collection('runs');

  CollectionReference<Map<String, dynamic>> get friendRequestsCollection =>
      firestore.collection('friend_requests');
}
