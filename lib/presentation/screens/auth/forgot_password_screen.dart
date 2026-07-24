import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/utils/validators.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/core/widgets/custom_text_field.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().sendPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.forgotPasswordLink)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSentMessage(context) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Введите email, указанный при регистрации — пришлём ссылку для сброса пароля.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailController,
            label: AppStrings.emailLabel,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: AppStrings.forgotPasswordButton,
            isLoading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          'Ссылка для сброса пароля отправлена на ${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        CustomButton(text: 'Назад ко входу', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
