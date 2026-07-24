import 'package:flutter/material.dart';
import 'package:streetrun/core/constants/app_strings.dart';

class TermsReadOnlyScreen extends StatelessWidget {
  const TermsReadOnlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTerms)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppStrings.termsFullText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
