import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/data/models/user_model.dart';
import 'package:streetrun/data/repositories/auth_repository.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Начальное состояние, пока не понятно, залогинен пользователь или нет.
class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

/// Пользователь зарегистрирован/вошёл, но ещё не подтвердил email.
class AuthEmailNotVerified extends AuthState {
  final String email;
  const AuthEmailNotVerified(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// Cubit авторизации. Держит "источник правды" о том, кто сейчас залогинен —
/// на него завязан редирект в go_router (см. app_router.dart).
/// Ошибки конкретных действий (неверный пароль и т.п.) не хранятся в
/// состоянии — методы просто пробрасывают исключение, а экран сам ловит
/// его в try/catch и показывает SnackBar.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSub;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _authSub = _authRepository.authStateChanges.listen(_onFirebaseUserChanged);
  }

  Future<void> _onFirebaseUserChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      await firebaseUser.reload();
    } catch (_) {
      // пользователь мог быть удалён на сервере — считаем разлогиненным
      emit(AuthUnauthenticated());
      return;
    }

    if (!firebaseUser.emailVerified) {
      emit(AuthEmailNotVerified(firebaseUser.email ?? ''));
      return;
    }

    try {
      final user = await _authRepository.getUserProfile(firebaseUser.uid);
      emit(AuthAuthenticated(user));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String nickname,
    String? gender,
    int? age,
  }) async {
    final user = await _authRepository.register(
      email: email,
      password: password,
      nickname: nickname,
      gender: gender,
      age: age,
    );
    emit(AuthEmailNotVerified(email));
    return user;
  }

  Future<void> login({required String email, required String password}) async {
    final user = await _authRepository.login(email: email, password: password);
    final verified = _authRepository.currentFirebaseUser?.emailVerified ?? false;
    emit(verified ? AuthAuthenticated(user) : AuthEmailNotVerified(email));
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> sendPasswordReset(String email) {
    return _authRepository.sendPasswordReset(email);
  }

  Future<void> resendVerificationEmail() {
    return _authRepository.resendVerificationEmail();
  }

  /// Возвращает true, если письмо уже подтверждено — заодно обновляет состояние.
  Future<bool> checkEmailVerifiedNow() async {
    final verified = await _authRepository.checkEmailVerified();
    if (verified) {
      final uid = _authRepository.currentFirebaseUser!.uid;
      final user = await _authRepository.getUserProfile(uid);
      emit(AuthAuthenticated(user));
    }
    return verified;
  }

  /// Перечитать профиль из Firestore, например после правок в настройках.
  Future<void> refreshProfile() async {
    final uid = _authRepository.currentFirebaseUser?.uid;
    if (uid == null) return;
    final user = await _authRepository.getUserProfile(uid);
    emit(AuthAuthenticated(user));
  }

  /// Вызывается наблюдателем жизненного цикла приложения (см. app.dart) при
  /// сворачивании/разворачивании — отдельно от logout(), который тоже
  /// проставляет isOnline: false.
  Future<void> updateOnlineStatus(bool isOnline) {
    return _authRepository.updateOnlineStatus(isOnline);
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
