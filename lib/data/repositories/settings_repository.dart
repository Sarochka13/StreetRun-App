import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetrun/data/models/user_model.dart';
import 'package:streetrun/data/services/cloudinary_service.dart';
import 'package:streetrun/data/services/firebase_service.dart';

/// Настройки приложения: тема и статус онбординга — в shared_preferences,
/// профиль — в Firestore (+ Cloudinary для новой аватарки).
class SettingsRepository {
  static const String _onboardingKey = 'onboarding_complete';
  static const String _themeKey = 'theme_mode';

  final AppFirebaseService _firebaseService;
  final CloudinaryService _cloudinaryService;

  SettingsRepository(this._firebaseService, this._cloudinaryService);

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Тёмная тема — по умолчанию, согласно ТЗ.
  Future<ThemeMode> getSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? gender,
    int? age,
    String? phone,
    File? newAvatar,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nickname != null && nickname.trim().isNotEmpty) data['nickname'] = nickname.trim();
      if (gender != null) data['gender'] = gender;
      if (age != null) data['age'] = age;
      if (phone != null) data['phone'] = phone;

      if (newAvatar != null) {
        data['avatarUrl'] = await _cloudinaryService.uploadAvatar(newAvatar);
      }

      if (data.isEmpty) return;
      await _firebaseService.usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Не удалось сохранить профиль: $e');
    }
  }

  /// Возвращает лучшие результаты по трём режимам (в секундах, null если рекорда ещё нет).
  Future<Map<String, double?>> getRecords(String uid) async {
    final doc = await _firebaseService.usersCollection.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return {'sprint': null, 'snake': null, 'timed': null};
    }
    final user = UserModel.fromMap(doc.data()!);
    return {
      'sprint': user.bestSprintSeconds,
      'snake': user.bestSnakeSeconds,
      'timed': user.bestTimedSeconds,
    };
  }
}
