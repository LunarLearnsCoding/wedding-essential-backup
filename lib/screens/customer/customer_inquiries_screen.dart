import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CustomerInquiriesScreen extends StatelessWidget {
  const CustomerInquiriesScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _inquiriesStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('inquiries')
        .where('customerId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> _cancelInquiry(BuildContext context, String inquiryId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Inquiry?'),
          content: const Text(
            'Are you sure you want to cancel this inquiry?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(inquiryId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inquiry cancelled'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel inquiry: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Inquiries'),
        ),
        body: const Center(
          child: Text('Please login to view your inquiries.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Inquiries'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _inquiriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final inquiries = snapshot.data?.docs ?? [];

          if (inquiries.isEmpty) {
            return const _EmptyInquiriesView();
          }

          inquiries.sort((a, b) {
            final aDate = _dateFromValue(a.data()['createdAt']);
            final bDate = _dateFromValue(b.data()['createdAt']);

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;

            return bDate.compareTo(aDate);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: inquiries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final inquiryDoc = inquiries[index];
              final data = inquiryDoc.data();

              return _InquiryCard(
                inquiryId: inquiryDoc.id,
                inquiryData: data,
                onCancel: () => _cancelInquiry(context, inquiryDoc.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyInquiriesView extends StatelessWidget {
  const _EmptyInquiriesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                color: AppColors.selectedSurface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No inquiries yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your service inquiries will appear here after you contact a vendor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final String inquiryId;
  final Map<String, dynamic> inquiryData;
  final VoidCallback onCancel;

  const _InquiryCard({
    required this.inquiryId,
    required this.inquiryData,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = _stringValue(
      inquiryData,
      'serviceName',
      fallback: 'Wedding Service',
    );

    final vendorName = _stringValue(
      inquiryData,
      'vendorName',
      fallback: 'Vendor',
    );

    final message = _stringValue(inquiryData, 'message');
    final vendorReply = _stringValue(inquiryData, 'vendorReply');

    final status = _stringValue(
      inquiryData,
      'status',
      fallback: 'pending',
    ).toLowerCase();

    final createdAt = _dateFromValue(inquiryData['createdAt']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.selectedSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mark_chat_unread_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),

          if (createdAt != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          const Text(
            'Your Message',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 7),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              message.isEmpty ? 'No message added.' : message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          if (vendorReply.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Vendor Reply',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.selectedSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                vendorReply,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          if (status == 'pending') ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel Inquiry'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() + status.substring(1);

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'replied':
      case 'answered':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'cancelled':
      case 'closed':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        backgroundColor = AppColors.selectedSurface;
        textColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _stringValue(
  Map<String, dynamic> data,
  String key, {
  String fallback = '',
}) {
  final value = data[key];

  if (value == null) return fallback;

  final text = value.toString().trim();

  if (text.isEmpty) return fallback;

  return text;
}

DateTime? _dateFromValue(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$year-$month-$day';
}