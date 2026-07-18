import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_enums.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';

class VendorInquiryDetailScreen extends StatefulWidget {
  final String inquiryId;

  const VendorInquiryDetailScreen({super.key, required this.inquiryId});

  @override
  State<VendorInquiryDetailScreen> createState() =>
      _VendorInquiryDetailScreenState();
}

class _VendorInquiryDetailScreenState extends State<VendorInquiryDetailScreen> {
  final InquiryService _inquiryService = InquiryService();
  final TextEditingController _replyController = TextEditingController();

  bool _isReplying = false;
  bool _isClosing = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply first')),
      );
      return;
    }

    setState(() {
      _isReplying = true;
    });

    try {
      await _inquiryService.replyToInquiry(
        inquiryId: widget.inquiryId,
        reply: text,
      );

      if (!mounted) return;

      _replyController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply sent successfully')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send reply: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isReplying = false;
        });
      }
    }
  }

  Future<void> _closeInquiry() async {
    setState(() {
      _isClosing = true;
    });

    try {
      await _inquiryService.closeInquiry(widget.inquiryId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inquiry closed')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to close inquiry: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClosing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<InquiryModel?>(
        stream: _inquiryService.watchInquiry(widget.inquiryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              title: 'Failed to load inquiry',
              message: snapshot.error.toString(),
            );
          }

          final inquiry = snapshot.data;

          if (inquiry == null) {
            return _MessageState(
              title: 'Inquiry unavailable',
              message: 'This inquiry is no longer available.',
              actionLabel: 'Back to inquiries',
              onAction: () => Navigator.maybePop(context),
            );
          }

          final status = _inquiryStatusLabel(inquiry.status);
          final isClosed = inquiry.status == InquiryStatus.closed;
          final isCancelled = inquiry.status == InquiryStatus.cancelled;
          final isInactive = isClosed || isCancelled;
          final canReply = inquiry.status == InquiryStatus.pending;
          final canClose =
              inquiry.status == InquiryStatus.pending ||
              inquiry.status == InquiryStatus.replied;
          final isBusy = _isReplying || _isClosing;
          final messages = _messagesFromInquiry(inquiry);

          return Column(
            children: [
              _InquiryDetailHeader(status: status),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CustomerInfoCard(inquiry: inquiry),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Conversation'),
                      const SizedBox(height: 14),
                      ...messages.map(
                        (message) => _MessageBubble(message: message),
                      ),
                      const SizedBox(height: 14),
                      if (canReply)
                        _ReplyBox(
                          controller: _replyController,
                          isSending: _isReplying,
                          onSend: isBusy ? null : _sendReply,
                        ),
                      if (canClose) const SizedBox(height: 12),
                      if (canClose)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isBusy ? null : _closeInquiry,
                            icon: _isClosing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.close),
                            label: Text(
                              _isClosing ? 'Closing...' : 'Close Inquiry',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      if (isInactive)
                        _ClosedNoticeCard(isCancelled: isCancelled),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _InquiryDetailHeader(status: 'Unavailable'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_chat_unread_outlined,
                    color: AppColors.primary,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(actionLabel!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InquiryDetailHeader extends StatelessWidget {
  final String status;

  const _InquiryDetailHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Inquiry Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: status),
        ],
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  final InquiryModel inquiry;

  const _CustomerInfoCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final customerName = _displayValue(inquiry.customerName, 'Customer');
    final serviceName = _displayValue(inquiry.serviceName, 'Wedding Service');
    final message = _displayValue(inquiry.message, 'No message added.');
    final createdAt = DateFormat(
      'MMM dd, yyyy h:mm a',
    ).format(inquiry.createdAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.selectedSurface,
                child: Text(
                  customerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceName,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('MMM dd').format(inquiry.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Created',
            value: createdAt,
          ),
          const SizedBox(height: 18),
          const Text(
            'Customer Message',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _MessageItem message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isVendor = message.isVendor;

    return Align(
      alignment: isVendor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isVendor ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isVendor ? 18 : 5),
            bottomRight: Radius.circular(isVendor ? 5 : 18),
          ),
          border: isVendor ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: TextStyle(
                color: isVendor ? Colors.white70 : AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.text,
              style: TextStyle(
                color: isVendor ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.time,
              style: TextStyle(
                color: isVendor
                    ? Colors.white.withValues(alpha: 0.65)
                    : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback? onSend;

  const _ReplyBox({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onSend,
                icon: isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(isSending ? 'Sending' : 'Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedNoticeCard extends StatelessWidget {
  final bool isCancelled;

  const _ClosedNoticeCard({required this.isCancelled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isCancelled ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCancelled
                  ? 'This inquiry was cancelled by the customer.'
                  : 'This inquiry has been closed.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (status == 'New') {
      backgroundColor = Colors.white.withValues(alpha: 0.18);
      textColor = Colors.white;
    } else if (status == 'Replied') {
      backgroundColor = Colors.green.withValues(alpha: 0.18);
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.grey.withValues(alpha: 0.25);
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MessageItem {
  final String senderName;
  final String text;
  final String time;
  final bool isVendor;

  const _MessageItem({
    required this.senderName,
    required this.text,
    required this.time,
    required this.isVendor,
  });
}

List<_MessageItem> _messagesFromInquiry(InquiryModel inquiry) {
  final customerName = _displayValue(inquiry.customerName, 'Customer');
  final customerMessage = _displayValue(inquiry.message, 'No message added.');
  final messages = [
    _MessageItem(
      senderName: customerName,
      text: customerMessage,
      time: DateFormat('MMM dd, h:mm a').format(inquiry.createdAt),
      isVendor: false,
    ),
  ];

  final vendorReply = inquiry.vendorReply.trim();

  if (vendorReply.isNotEmpty) {
    messages.add(
      _MessageItem(
        senderName: 'You',
        text: vendorReply,
        time: inquiry.vendorReplyAt == null
            ? 'Reply sent'
            : DateFormat('MMM dd, h:mm a').format(inquiry.vendorReplyAt!),
        isVendor: true,
      ),
    );
  }

  return messages;
}

String _inquiryStatusLabel(InquiryStatus status) {
  switch (status) {
    case InquiryStatus.pending:
      return 'New';
    case InquiryStatus.replied:
      return 'Replied';
    case InquiryStatus.closed:
      return 'Closed';
    case InquiryStatus.cancelled:
      return 'Cancelled';
  }
}

String _displayValue(String value, String fallback) {
  final text = value.trim();

  if (text.isEmpty) {
    return fallback;
  }

  return text;
}
