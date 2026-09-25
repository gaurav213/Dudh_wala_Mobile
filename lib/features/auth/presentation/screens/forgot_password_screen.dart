import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

/// OTP reset is planned; this screen documents the future flow.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dk.of(context).cream,
      appBar: AppBar(title: Text(AppLocalizations.of(context).forgotPassword)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).otpPasswordReset,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).smsOtpLaterRelease,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).contactAdminResetAccess,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Dk.of(context).muted),
            ),
            const SizedBox(height: 24),
            Chip(label: Text(AppLocalizations.of(context).futureOtpSms)),
          ],
        ),
      ),
    );
  }
}
