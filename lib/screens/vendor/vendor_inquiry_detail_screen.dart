import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class VendorInquiryDetailScreen extends StatefulWidget {
  const VendorInquiryDetailScreen({super.key});

  @override
  State<VendorInquiryDetailScreen> createState() =>
      _VendorInquiryDetailScreenState();
}

class _VendorInquiryDetailScreenState extends State<VendorInquiryDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  String _status = 'New';

  final List<_MessageItem> _messages = [
    const _MessageItem(
      senderName: 'Aarati Sharma',
      text:
          'Hello, I wanted to know if your photography package is available for January 15.',
      time: 'Today',
      isVendor: false,
    ),
  ];

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _MessageItem(
          senderName: 'You',
          text: text,
          time: 'Just now',
          isVendor: true,
        ),
      );

      _status = 'Replied';
      _replyController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reply sent successfully')));
  }

  void _closeInquiry() {
    setState(() {
      _status = 'Closed';
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Inquiry closed')));
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _status == 'Closed';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _InquiryDetailHeader(status: _status),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CustomerInfoCard(),

                  const SizedBox(height: 24),

                  const _SectionHeader(title: 'Conversation'),

                  const SizedBox(height: 14),

                  ..._messages.map(
                    (message) => _MessageBubble(message: message),
                  ),

                  const SizedBox(height: 14),

                  if (!isClosed)
                    _ReplyBox(controller: _replyController, onSend: _sendReply),

                  if (!isClosed) const SizedBox(height: 12),

                  if (!isClosed)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _closeInquiry,
                        icon: const Icon(Icons.close),
                        label: const Text('Close Inquiry'),
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

                  if (isClosed) const _ClosedNoticeCard(),
                ],
              ),
            ),
          ),
        ],
      ),
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
  const _CustomerInfoCard();

  @override
  Widget build(BuildContext context) {
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
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.selectedSurface,
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aarati Sharma',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Royal Photography',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                'Today',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Event Date',
            value: '15 Jan 2026',
          ),

          const SizedBox(height: 10),

          const _InfoRow(
            icon: Icons.group_outlined,
            label: 'Guests',
            value: '300 pax',
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

          const Text(
            'Hello, I wanted to know if your photography package is available for January 15.',
            style: TextStyle(
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
  final VoidCallback onSend;

  const _ReplyBox({required this.controller, required this.onSend});

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

          ElevatedButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedNoticeCard extends StatelessWidget {
  const _ClosedNoticeCard();

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
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This inquiry has been closed.',
              style: TextStyle(
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
