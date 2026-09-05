import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/chat_list_header.dart';
import '../../core/widgets/content_message_state.dart';
import '../../core/widgets/inquiry_list_card.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';
import '../shared/inquiry_chat_screen.dart';

/// Displays the vendor inquiries page and coordinates the actions available on it.
class VendorInquiriesScreen extends StatefulWidget {
  const VendorInquiriesScreen({super.key});

  @override
  State<VendorInquiriesScreen> createState() => _VendorInquiriesScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorInquiriesScreenState extends State<VendorInquiriesScreen> {
  final InquiryService _service = InquiryService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<InquiryModel>>(
        stream: _service.getVendorInquiries(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ContentMessageState(
              icon: Icons.error_outline,
              title: 'Failed to load chats',
              message: snapshot.error.toString(),
            );
          }

          final allChats = snapshot.data ?? [];
          final query = _searchController.text.trim().toLowerCase();
          final chats = allChats.where((chat) {
            final matchesSearch =
                query.isEmpty ||
                chat.customerName.toLowerCase().contains(query) ||
                chat.customerEmail.toLowerCase().contains(query) ||
                chat.serviceName.toLowerCase().contains(query) ||
                chat.lastMessage.toLowerCase().contains(query) ||
                chat.message.toLowerCase().contains(query);
            return matchesSearch;
          }).toList();

          return Column(
            children: [
              ChatListHeader(
                accountLabel: 'Vendor Account',
                title: 'Customer Chats',
                chatCount: allChats.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search customer, email, or service...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: chats.isEmpty
                    ? const ContentMessageState(
                        icon: Icons.forum_outlined,
                        title: 'No chats found',
                        message:
                            'New customer conversations will appear here in real time.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return InquiryListCard(
                            inquiry: chat,
                            participantId: chat.customerId,
                            participantName: _value(
                              chat.customerName,
                              'Customer',
                            ),
                            unread: chat.unreadForVendor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InquiryChatScreen(
                                  inquiryId: chat.id,
                                  isVendor: true,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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
