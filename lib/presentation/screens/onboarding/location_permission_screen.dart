import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/data/services/gps_service.dart';

/// Первый экран онбординга — запрашиваем доступ к геолокации, без него
/// главная механика приложения (запись забега) не работает.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final _gpsService = GpsService();
  bool _requesting = false;

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    try {
      final granted = await _gpsService.ensureLocationPermission();
      if (!mounted) return;
      if (granted) {
        context.go(AppRoutes.onboardingTerms);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Без доступа к GPS забег не запишется. Разрешить доступ можно позже в настройках телефона.',
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 96, color: AppColors.neonBlue),
              const SizedBox(height: 32),
              Text(
                AppStrings.locationPermissionTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.locationPermissionBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: AppStrings.locationPermissionButton,
                isLoading: _requesting,
                onPressed: _requestPermission,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go(AppRoutes.onboardingTerms),
                child: const Text('Пропустить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
