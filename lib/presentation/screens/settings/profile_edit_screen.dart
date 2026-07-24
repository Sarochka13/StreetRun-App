import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streetrun/core/constants/app_strings.dart';
import 'package:streetrun/core/utils/validators.dart';
import 'package:streetrun/core/widgets/custom_button.dart';
import 'package:streetrun/core/widgets/custom_text_field.dart';
import 'package:streetrun/core/widgets/user_avatar.dart';
import 'package:streetrun/presentation/bloc/auth/auth_cubit.dart';
import 'package:streetrun/presentation/bloc/settings/settings_cubit.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;
  late final TextEditingController _ageController;
  late final TextEditingController _phoneController;
  String? _gender;
  File? _newAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    final user = state is AuthAuthenticated ? state.user : null;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _newAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final authCubit = context.read<AuthCubit>();

    setState(() => _saving = true);
    try {
      await context.read<SettingsCubit>().updateProfile(
            uid: authState.user.uid,
            nickname: _nicknameController.text.trim(),
            gender: _gender,
            age: int.tryParse(_ageController.text.trim()),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            newAvatar: _newAvatar,
          );
      await authCubit.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentAvatarUrl = authState is AuthAuthenticated ? authState.user.avatarUrl : null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsPersonalization)),
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
                        _newAvatar != null
                            ? CircleAvatar(radius: 48, backgroundImage: FileImage(_newAvatar!))
                            : UserAvatar(avatarUrl: currentAvatarUrl, radius: 48),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(radius: 15, child: Icon(Icons.edit, size: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
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
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Телефон (опционально)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 28),
                CustomButton(text: 'Сохранить', isLoading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
