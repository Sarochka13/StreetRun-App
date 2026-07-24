import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/core/constants/app_colors.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      final verified = await context.read<AuthCubit>().checkEmailVerifiedNow();
      // При успехе AuthCubit сам перейдёт в AuthAuthenticated, а роутер
      // перенаправит на главное меню — здесь достаточно сообщить, если нет.
      if (!verified && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Почта пока не подтверждена. Проверьте письмо и попробуйте снова.'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await context.read<AuthCubit>().resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Письмо отправлено повторно')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final email = state is AuthEmailNotVerified ? state.email : '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 88, color: AppColors.neonBlue),
              const SizedBox(height: 24),
              Text(
                'Мы отправили письмо на $email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Перейдите по ссылке в письме, затем вернитесь сюда и нажмите кнопку ниже.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: AppStrings.verifyEmailButtonConfirmed,
                isLoading: _checking,
                onPressed: _checkVerified,
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: AppStrings.verifyEmailButtonResend,
                isLoading: _resending,
                onPressed: _resend,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
