import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_information_sheet.dart';

class LegalAgreement extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LegalAgreement({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          activeColor: AppColors.primary,
          onChanged: (checked) => onChanged(checked ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'I agree to the ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => _showTerms(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Terms of Service'),
                ),
                const Text(
                  ' and ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () => _showPrivacy(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Privacy Policy'),
                ),
                const Text(
                  '.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTerms(BuildContext context) {
    return showAppInformationSheet(
      context,
      title: 'Terms of Service',
      icon: Icons.description_outlined,
      message:
          'Use Wedding Essentials only for lawful wedding-planning activities. Provide accurate account and booking information, respect vendors and customers, and do not misuse messages, reviews, or payments. Bookings remain subject to vendor confirmation, availability, pricing, cancellation terms, and any agreement made with the vendor.',
      buttonLabel: 'Close',
    );
  }

  Future<void> _showPrivacy(BuildContext context) {
    return showAppInformationSheet(
      context,
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      message:
          'We store the account, profile, booking, inquiry, checklist, guest-list, favorite, and review information needed to provide the app. Relevant contact and booking details are shared with the vendor or customer involved in a request. Keep your account secure and contact support if you need your information corrected or removed.',
      buttonLabel: 'Close',
    );
  }
}
