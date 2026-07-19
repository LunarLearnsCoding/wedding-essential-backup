import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../constants/admin_account.dart';

class SupportContactCard extends StatelessWidget {
  const SupportContactCard({
    super.key,
    this.title = 'We’re here to help',
    this.message =
        'For support and account assistance, email $adminAccountEmail.',
    this.emailSubject = 'Support',
    this.emailBody,
  });

  final String title;
  final String message;
  final String emailSubject;
  final String? emailBody;

  Future<void> _emailSupport(BuildContext context) async {
    final opened = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: adminAccountEmail,
        queryParameters: {
          'subject': emailSubject,
          if (emailBody != null) 'body': emailBody!,
        },
      ),
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open an email application.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                _SupportMessage(message: message),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Email admin',
            onPressed: () => _emailSupport(context),
            icon: const Icon(
              Icons.email_outlined,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportMessage extends StatelessWidget {
  const _SupportMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final emailIndex = message.indexOf(adminAccountEmail);
    if (emailIndex < 0) {
      return Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      );
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(color: AppColors.textSecondary),
        children: [
          TextSpan(text: message.substring(0, emailIndex)),
          const TextSpan(
            text: adminAccountEmail,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: message.substring(emailIndex + adminAccountEmail.length),
          ),
        ],
      ),
    );
  }
}
