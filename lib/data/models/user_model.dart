import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель пользователя. Хранится в коллекции Firestore `users/{uid}`.
class UserModel {
  // обязательные поля
  final String uid;
  final String email;
  final String nickname;
  final DateTime registrationDate;

  // опциональные поля
  final String? avatarUrl;
  final String? gender;
  final int? age;
  final String? phone;

  // автоматические поля
  final DateTime? lastOnline;
  final bool isOnline;
  final bool isEmailVerified;

  // рекорды (в секундах, null пока рекорда нет)
  final double? bestSprintSeconds;
  final double? bestSnakeSeconds;
  final double? bestTimedSeconds;

  const UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.registrationDate,
    this.avatarUrl,
    this.gender,
    this.age,
    this.phone,
    this.lastOnline,
    this.isOnline = false,
    this.isEmailVerified = false,
    this.bestSprintSeconds,
    this.bestSnakeSeconds,
    this.bestTimedSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'registrationDate': Timestamp.fromDate(registrationDate),
      'avatarUrl': avatarUrl,
      'gender': gender,
      'age': age,
      'phone': phone,
      'lastOnline': lastOnline != null ? Timestamp.fromDate(lastOnline!) : null,
      'isOnline': isOnline,
      'isEmailVerified': isEmailVerified,
      'bestSprintSeconds': bestSprintSeconds,
      'bestSnakeSeconds': bestSnakeSeconds,
      'bestTimedSeconds': bestTimedSeconds,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      nickname: map['nickname'] as String,
      registrationDate: (map['registrationDate'] as Timestamp).toDate(),
      avatarUrl: map['avatarUrl'] as String?,
      gender: map['gender'] as String?,
      age: map['age'] as int?,
      phone: map['phone'] as String?,
      lastOnline: (map['lastOnline'] as Timestamp?)?.toDate(),
      isOnline: map['isOnline'] as bool? ?? false,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      bestSprintSeconds: (map['bestSprintSeconds'] as num?)?.toDouble(),
      bestSnakeSeconds: (map['bestSnakeSeconds'] as num?)?.toDouble(),
      bestTimedSeconds: (map['bestTimedSeconds'] as num?)?.toDouble(),
    );
  }

  UserModel copyWith({
    String? nickname,
    String? avatarUrl,
    String? gender,
    int? age,
    String? phone,
    DateTime? lastOnline,
    bool? isOnline,
    bool? isEmailVerified,
    double? bestSprintSeconds,
    double? bestSnakeSeconds,
    double? bestTimedSeconds,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      nickname: nickname ?? this.nickname,
      registrationDate: registrationDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      lastOnline: lastOnline ?? this.lastOnline,
      isOnline: isOnline ?? this.isOnline,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      bestSprintSeconds: bestSprintSeconds ?? this.bestSprintSeconds,
      bestSnakeSeconds: bestSnakeSeconds ?? this.bestSnakeSeconds,
      bestTimedSeconds: bestTimedSeconds ?? this.bestTimedSeconds,
    );
  }
}
