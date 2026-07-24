import 'package:flutter/material.dart';

/// Цветовая палитра приложения.
/// Тёмная тема — основная (по ТЗ), светлая — дополнительная.
class AppColors {
  AppColors._(); // не даём создавать экземпляры, это просто набор констант

  // ---- Тёмная тема ----
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF161616);
  static const Color darkSurfaceVariant = Color(0xFF222222);
  static const Color neonBlue = Color(0xFF00D4FF); // основной акцент
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);

  // ---- Светлая тема ----
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF3F5F7);
  static const Color lightAccentBlue = Color(0xFF0077C2); // синий акцент
  static const Color lightTextPrimary = Color(0xFF101418);
  static const Color lightTextSecondary = Color(0xFF5B6470);

  // ---- Общие статусные цвета (не зависят от темы) ----
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF4D4F);
  static const Color online = Color(0xFF2ECC71);
  static const Color offline = Color(0xFF8A8A8A);
}
