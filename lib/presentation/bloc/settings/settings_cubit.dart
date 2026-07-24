import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/data/repositories/settings_repository.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool onboardingComplete;
  final bool isLoaded;

  const SettingsState({
    required this.themeMode,
    required this.onboardingComplete,
    this.isLoaded = false,
  });

  SettingsState copyWith({ThemeMode? themeMode, bool? onboardingComplete, bool? isLoaded}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [themeMode, onboardingComplete, isLoaded];
}

/// Cubit настроек: тема (тёмная по умолчанию) и флаг "онбординг пройден",
/// от которого зависит редирект в go_router на первом запуске.
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsCubit(this._settingsRepository)
      : super(const SettingsState(themeMode: ThemeMode.dark, onboardingComplete: false));

  /// Вызывается один раз при старте приложения (см. app.dart).
  Future<void> loadInitial() async {
    final theme = await _settingsRepository.getSavedThemeMode();
    final onboarding = await _settingsRepository.isOnboardingComplete();
    emit(state.copyWith(themeMode: theme, onboardingComplete: onboarding, isLoaded: true));
  }

  Future<void> toggleTheme() async {
    final next = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _settingsRepository.saveThemeMode(next);
    emit(state.copyWith(themeMode: next));
  }

  Future<void> completeOnboarding() async {
    await _settingsRepository.setOnboardingComplete();
    emit(state.copyWith(onboardingComplete: true));
  }

  Future<void> updateProfile({
    required String uid,
    String? nickname,
    String? gender,
    int? age,
    String? phone,
    File? newAvatar,
  }) {
    return _settingsRepository.updateProfile(
      uid: uid,
      nickname: nickname,
      gender: gender,
      age: age,
      phone: phone,
      newAvatar: newAvatar,
    );
  }

  Future<Map<String, double?>> getRecords(String uid) {
    return _settingsRepository.getRecords(uid);
  }
}
