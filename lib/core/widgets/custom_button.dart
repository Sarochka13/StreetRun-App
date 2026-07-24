import 'package:flutter/material.dart';
import 'package:streetrun/core/constants/app_colors.dart';

/// Основная кнопка приложения. Умеет показывать индикатор загрузки
/// вместо текста, чтобы не плодить отдельные "loading"-кнопки на каждом экране.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

/// Кнопка второго плана — просто текст с акцентным цветом, без заливки.
/// Используется для ссылок вида "Забыли пароль?".
class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const CustomTextButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? AppColors.neonBlue : AppColors.lightAccentBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
