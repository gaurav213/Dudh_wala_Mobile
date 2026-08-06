import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// OTP reset is planned; this screen documents the future flow.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OTP password reset',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'SMS OTP verification will land in a later release. '
              'For now, contact your Doodh Khata admin to reset access.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            const Chip(label: Text('Future: OTP via SMS')),
          ],
        ),
      ),
    );
  }
}
