import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streetrun/core/constants/app_routes.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/utils/validators.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/core/widgets/custom_text_field.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender; // 'male' | 'female', опционально
  File? _avatarFile;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nickname: _nicknameController.text.trim(),
            gender: _gender,
            age: int.tryParse(_ageController.text.trim()),
          );

      if (!mounted) return;

      if (_avatarFile != null) {
        // Аватарка опциональна — если её загрузка не удалась, не валим всю
        // регистрацию, просто пользователь останется с силуэтом по умолчанию.
        try {
          await context.read<SettingsCubit>().updateProfile(uid: user.uid, newAvatar: _avatarFile);
        } catch (_) {}
      }

      if (!mounted) return;
      context.go(AppRoutes.verifyEmail);
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
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        _avatarFile != null
                            ? CircleAvatar(radius: 44, backgroundImage: FileImage(_avatarFile!))
                            : const UserAvatar(avatarUrl: null, radius: 44),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 14,
                            child: Icon(Icons.edit, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: AppStrings.passwordLabel,
                  obscureText: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nicknameController,
                  label: AppStrings.nicknameLabel,
                  validator: Validators.nickname,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: AppStrings.genderLabel),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Мужской')),
                          DropdownMenuItem(value: 'female', child: Text('Женский')),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _ageController,
                        label: AppStrings.ageLabel,
                        keyboardType: TextInputType.number,
                        validator: Validators.age,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: AppStrings.registerButton,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
