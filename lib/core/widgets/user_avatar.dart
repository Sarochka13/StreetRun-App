import 'package:flutter/material.dart';
import 'package:streetrun/core/constants/app_colors.dart';

/// Аватарка пользователя. Если avatarUrl пустой/null — показываем
/// системный силуэт с вопросом, как требует ТЗ.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final bool? isOnline; // null -> не показывать индикатор онлайна

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 24,
    this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.darkSurfaceVariant,
      backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: hasAvatar
          ? null
          : Icon(
              Icons.person_outline,
              size: radius,
              color: AppColors.darkTextSecondary,
            ),
    );

    if (isOnline == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: radius * 0.42,
            height: radius * 0.42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline! ? AppColors.online : AppColors.offline,
              border: Border.all(color: AppColors.darkBackground, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
