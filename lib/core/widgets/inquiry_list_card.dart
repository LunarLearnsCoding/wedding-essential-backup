import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/inquiry_model.dart';
import '../constants/app_colors.dart';
import 'profile_avatar.dart';

/// Renders the reusable inquiry list card UI component.
class InquiryListCard extends StatelessWidget {
  const InquiryListCard({
    super.key,
    required this.inquiry,
    required this.participantId,
    required this.participantName,
    required this.unread,
    required this.onTap,
    this.participantEmail = '',
  });

  final InquiryModel inquiry;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _value(participantName, 'Participant');
    final preview = _value(
      inquiry.lastMessage,
      _value(inquiry.vendorReply, _value(inquiry.message, 'Open conversation')),
    );
    final time =
        inquiry.lastMessageAt ?? inquiry.updatedAt ?? inquiry.createdAt;
    final email = participantEmail.trim();

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    userId: participantId,
                    fallbackName: name,
                    radius: 25,
                  ),
                  if (unread)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a').format(time),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    SizedBox(height: email.isEmpty ? 3 : 5),
                    Text(
                      'Conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

String _value(String value, String fallback) {
  final text = value.trim();
  return text.isEmpty ? fallback : text;
}
