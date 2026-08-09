import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/content_message_state.dart';
import '../../core/widgets/inquiry_list_card.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';
import '../shared/inquiry_chat_screen.dart';

/// Displays the customer inquiries page and coordinates the actions available on it.
class CustomerInquiriesScreen extends StatefulWidget {
  const CustomerInquiriesScreen({super.key});

  @override
  State<CustomerInquiriesScreen> createState() =>
      _CustomerInquiriesScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _CustomerInquiriesScreenState extends State<CustomerInquiriesScreen> {
  final InquiryService _service = InquiryService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Chats')),
        body: const Center(child: Text('Please login to view your chats.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Chats')),
      body: StreamBuilder<List<InquiryModel>>(
        stream: _service.getCustomerInquiries(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ContentMessageState(
              icon: Icons.error_outline,
              title: 'Could not load chats',
              message: snapshot.error.toString(),
            );
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const ContentMessageState(
              icon: Icons.forum_outlined,
              title: 'No chats yet',
              message:
                  'Contact a vendor from a service page to start a conversation.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return InquiryListCard(
                inquiry: chat,
                participantId: chat.vendorId,
                participantName: _value(chat.vendorName, 'Vendor'),
                unread: chat.unreadForCustomer,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InquiryChatScreen(inquiryId: chat.id, isVendor: false),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _value(String value, String fallback) {
  final text = value.trim();
  return text.isEmpty ? fallback : text;
}
