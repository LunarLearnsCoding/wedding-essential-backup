import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/inquiry_message_model.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';

class InquiryChatScreen extends StatefulWidget {
  final String inquiryId;
  final bool isVendor;

  const InquiryChatScreen({
    super.key,
    required this.inquiryId,
    required this.isVendor,
  });

  @override
  State<InquiryChatScreen> createState() => _InquiryChatScreenState();
}

class _InquiryChatScreenState extends State<InquiryChatScreen> {
  final InquiryService _service = InquiryService();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isMarkingRead = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send(InquiryModel inquiry) async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();
    if (user == null || text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _service.sendMessage(
        inquiryId: inquiry.id,
        senderId: user.uid,
        senderName: widget.isVendor
            ? _value(inquiry.vendorName, 'Vendor')
            : _value(inquiry.customerName, 'Customer'),
        senderEmail: widget.isVendor ? user.email ?? '' : inquiry.customerEmail,
        text: text,
      );
      _messageController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send message: $error')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _markRead() async {
    if (_isMarkingRead) return;
    _isMarkingRead = true;
    try {
      await _service.markChatRead(
        inquiryId: widget.inquiryId,
        isVendor: widget.isVendor,
      );
    } catch (_) {
      // Keep the chat usable if updated rules have not been deployed yet.
    } finally {
      _isMarkingRead = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InquiryModel?>(
      stream: _service.watchInquiry(widget.inquiryId),
      builder: (context, inquirySnapshot) {
        if (inquirySnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (inquirySnapshot.hasError || inquirySnapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Chat')),
            body: Center(
              child: Text(
                inquirySnapshot.hasError
                    ? 'Could not load chat: ${inquirySnapshot.error}'
                    : 'This chat is no longer available.',
              ),
            ),
          );
        }

        final inquiry = inquirySnapshot.data!;
        final hasUnread = widget.isVendor
            ? inquiry.unreadForVendor
            : inquiry.unreadForCustomer;
        if (hasUnread) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
        }
        final otherName = widget.isVendor
            ? _value(inquiry.customerName, 'Customer')
            : _value(inquiry.vendorName, 'Vendor');
        final otherEmail = widget.isVendor ? inquiry.customerEmail.trim() : '';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17),
                ),
                Text(
                  otherEmail.isNotEmpty
                      ? otherEmail
                      : _value(inquiry.serviceName, 'Wedding service'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              _ConversationBanner(inquiry: inquiry),
              Expanded(
                child: StreamBuilder<List<InquiryMessageModel>>(
                  stream: _service.watchMessages(inquiry.id),
                  builder: (context, messageSnapshot) {
                    if (messageSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (messageSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load messages: ${messageSnapshot.error}',
                        ),
                      );
                    }

                    final messages = messageSnapshot.data ?? [];
                    return _MessageHistory(
                      inquiry: inquiry,
                      messages: messages,
                    );
                  },
                ),
              ),
              _Composer(
                controller: _messageController,
                isSending: _isSending,
                onSend: () => _send(inquiry),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConversationBanner extends StatelessWidget {
  final InquiryModel inquiry;

  const _ConversationBanner({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: AppColors.selectedSurface,
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_value(inquiry.serviceName, 'Wedding service')} • Conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageHistory extends StatelessWidget {
  final InquiryModel inquiry;
  final List<InquiryMessageModel> messages;

  const _MessageHistory({required this.inquiry, required this.messages});

  @override
  Widget build(BuildContext context) {
    final displayMessages = inquiry.isRealtimeChat
        ? messages
        : [..._legacyMessages(inquiry), ...messages];
    if (displayMessages.isEmpty) {
      return const Center(child: Text('No messages in this chat.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      itemCount: displayMessages.length,
      itemBuilder: (context, index) {
        final message = displayMessages[index];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isMine = message.senderId == currentUserId;
        final showDate =
            index == 0 ||
            !_sameDay(displayMessages[index - 1].createdAt, message.createdAt);
        return Column(
          children: [
            if (showDate) _DateDivider(date: message.createdAt),
            _MessageBubble(message: message, isMine: isMine),
          ],
        );
      },
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        DateFormat('EEEE, MMM d, yyyy').format(date),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final InquiryMessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final avatar = _MessageAvatar(name: message.senderName, isMine: isMine);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[avatar, const SizedBox(width: 7)],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    border: isMine ? null : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMine ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(message.createdAt),
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.65)
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMine) ...[const SizedBox(width: 7), avatar],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageAvatar extends StatelessWidget {
  final String name;
  final bool isMine;

  const _MessageAvatar({required this.name, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    return CircleAvatar(
      radius: 15,
      backgroundColor: isMine
          ? AppColors.primary.withValues(alpha: 0.18)
          : AppColors.selectedSurface,
      child: cleanName.isEmpty
          ? const Icon(Icons.person_outline, size: 17, color: AppColors.primary)
          : Text(
              cleanName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: isSending
                  ? const SizedBox(
                      height: 19,
                      width: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

List<InquiryMessageModel> _legacyMessages(InquiryModel inquiry) {
  final messages = <InquiryMessageModel>[];
  if (inquiry.message.trim().isNotEmpty) {
    messages.add(
      InquiryMessageModel(
        id: 'legacy-customer',
        senderId: inquiry.customerId,
        senderName: inquiry.customerName,
        senderEmail: inquiry.customerEmail,
        text: inquiry.message.trim(),
        createdAt: inquiry.createdAt,
      ),
    );
  }
  if (inquiry.vendorReply.trim().isNotEmpty) {
    messages.add(
      InquiryMessageModel(
        id: 'legacy-vendor',
        senderId: inquiry.vendorId,
        senderName: inquiry.vendorName,
        senderEmail: '',
        text: inquiry.vendorReply.trim(),
        createdAt:
            inquiry.vendorReplyAt ?? inquiry.updatedAt ?? inquiry.createdAt,
      ),
    );
  }
  return messages;
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _value(String value, String fallback) {
  final text = value.trim();
  return text.isEmpty ? fallback : text;
}
