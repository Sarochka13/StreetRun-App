import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';

/// Второй экран онбординга — пользовательское соглашение. После галочки
/// и "Продолжить" go_router сам перенаправит дальше (см. app_router.dart),
/// так как onboardingComplete станет true.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.termsTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    AppStrings.termsFullText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.termsAcceptCheckbox),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: AppStrings.termsContinueButton,
                onPressed: _accepted
                    ? () => context.read<SettingsCubit>().completeOnboarding()
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
