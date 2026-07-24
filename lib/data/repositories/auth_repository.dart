import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:streetrun/data/models/user_model.dart';
import 'package:streetrun/data/services/firebase_service.dart';

/// Репозиторий авторизации. Прячет от остального приложения детали
/// Firebase Auth + документ пользователя в Firestore.
class AuthRepository {
  final AppFirebaseService _firebaseService;

  AuthRepository(this._firebaseService);

  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  User? get currentFirebaseUser => _firebaseService.currentUser;

  Future<UserModel> register({
    required String email,
    required String password,
    required String nickname,
    String? gender,
    int? age,
  }) async {
    try {
      final credential = await _firebaseService.signUp(email: email, password: password);
      final uid = credential.user!.uid;

      final userModel = UserModel(
        uid: uid,
        email: email,
        nickname: nickname,
        registrationDate: DateTime.now(),
        gender: gender,
        age: age,
        isOnline: true,
        isEmailVerified: false,
      );

      await _firebaseService.usersCollection.doc(uid).set(userModel.toMap());
      await _firebaseService.sendEmailVerification();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      throw Exception('Не удалось зарегистрироваться: $e');
    }
  }

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final credential = await _firebaseService.signIn(email: email, password: password);
      final uid = credential.user!.uid;
      await _setOnlineStatus(uid, true);
      return await getUserProfile(uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  Future<void> logout() async {
    try {
      final uid = _firebaseService.currentUser?.uid;
      if (uid != null) {
        await _setOnlineStatus(uid, false);
      }
      await _firebaseService.signOut();
    } catch (e) {
      throw Exception('Не удалось выйти из аккаунта: $e');
    }
  }

  Future<UserModel> getUserProfile(String uid) async {
    try {
      final doc = await _firebaseService.usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Профиль пользователя не найден');
      }
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Не удалось загрузить профиль: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseService.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _firebaseService.sendEmailVerification();
    } catch (e) {
      throw Exception('Не удалось отправить письмо: $e');
    }
  }

  /// Firebase не обновляет emailVerified сам по себе — нужно принудительно
  /// перезапросить состояние пользователя.
  Future<bool> checkEmailVerified() {
    return _firebaseService.reloadAndCheckEmailVerified();
  }

  Future<void> _setOnlineStatus(String uid, bool isOnline) async {
    await _firebaseService.usersCollection.doc(uid).update({
      'isOnline': isOnline,
      'lastOnline': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Отдельный публичный метод — вызывается из наблюдателя жизненного цикла
  /// приложения (см. app.dart), чтобы обновлять онлайн-статус при
  /// сворачивании/разворачивании, а не только при явном выходе.
  Future<void> updateOnlineStatus(bool isOnline) async {
    final uid = _firebaseService.currentUser?.uid;
    if (uid != null) {
      await _setOnlineStatus(uid, isOnline);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Некорректный email';
      case 'weak-password':
        return 'Пароль слишком простой';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      default:
        return e.message ?? 'Ошибка авторизации';
    }
  }
}
