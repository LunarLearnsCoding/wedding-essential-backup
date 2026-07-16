import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_enums.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';
import 'vendor_inquiry_detail_screen.dart';

class VendorInquiriesScreen extends StatefulWidget {
  const VendorInquiriesScreen({super.key});

  @override
  State<VendorInquiriesScreen> createState() => _VendorInquiriesScreenState();
}

class _VendorInquiriesScreenState extends State<VendorInquiriesScreen> {
  final InquiryService _inquiryService = InquiryService();
  String _query = '';
  String _selectedFilter = 'All';

  List<_InquiryItem> _filteredInquiries(List<_InquiryItem> inquiries) {
    final q = _query.toLowerCase().trim();

    return inquiries.where((inquiry) {
      final matchesSearch =
          q.isEmpty ||
          inquiry.customerName.toLowerCase().contains(q) ||
          inquiry.service.toLowerCase().contains(q) ||
          inquiry.message.toLowerCase().contains(q);

      final matchesFilter =
          _selectedFilter == 'All' || inquiry.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int _newInquiryCount(List<_InquiryItem> inquiries) {
    return inquiries.where((item) => item.status == 'New').length;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<InquiryModel>>(
        stream: _inquiryService.getVendorInquiries(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load inquiries: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final inquiries =
              (snapshot.data ?? []).map(_InquiryItem.fromModel).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final filteredInquiries = _filteredInquiries(inquiries);

          return Column(
            children: [
              _InquiriesHeader(newInquiryCount: _newInquiryCount(inquiries)),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SearchBox(
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      _InquiryFilterTabs(
                        selectedFilter: _selectedFilter,
                        inquiries: inquiries,
                        onChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),

                      const SizedBox(height: 28),

                      _SectionHeader(
                        title: 'Customer Inquiries',
                        actionText: '${filteredInquiries.length} found',
                      ),

                      const SizedBox(height: 14),

                      if (filteredInquiries.isEmpty)
                        const _EmptyInquiriesCard()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredInquiries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final inquiry = filteredInquiries[index];

                            return _InquiryCard(
                              inquiry: inquiry,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VendorInquiryDetailScreen(
                                      inquiryId: inquiry.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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

class _InquiriesHeader extends StatelessWidget {
  final int newInquiryCount;

  const _InquiriesHeader({required this.newInquiryCount});

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
                  'Inquiries',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          if (newInquiryCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                '$newInquiryCount new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by customer, service, or message...',
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _InquiryFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final List<_InquiryItem> inquiries;
  final ValueChanged<String> onChanged;

  const _InquiryFilterTabs({
    required this.selectedFilter,
    required this.inquiries,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'New', 'Replied', 'Closed'];

    return Row(
      children: filters.map((filter) {
        final isSelected = selectedFilter == filter;

        final count = filter == 'All'
            ? inquiries.length
            : inquiries.where((item) => item.status == filter).length;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                onChanged(filter);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$filter $count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          actionText,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final _InquiryItem inquiry;
  final VoidCallback onTap;

  const _InquiryCard({required this.inquiry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNew = inquiry.status == 'New';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isNew ? AppColors.primary : AppColors.border,
            width: isNew ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(text: inquiry.avatar),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          inquiry.customerName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: isNew
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        inquiry.date,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    inquiry.service,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    inquiry.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (inquiry.eventDate != 'TBC')
                        _TinyInfo(
                          icon: Icons.calendar_today_outlined,
                          text: inquiry.eventDate,
                        ),

                      if (inquiry.pax != null)
                        _TinyInfo(
                          icon: Icons.group_outlined,
                          text: inquiry.pax!,
                        ),

                      _TinyInfo(
                        icon: Icons.forum_outlined,
                        text: inquiry.replies,
                      ),

                      _StatusBadge(status: inquiry.status),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;

  const _Avatar({required this.text});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.selectedSurface,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
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
      backgroundColor = AppColors.primary.withValues(alpha: 0.12);
      textColor = AppColors.primary;
    } else if (status == 'Replied') {
      backgroundColor = Colors.green.withValues(alpha: 0.12);
      textColor = Colors.green;
    } else {
      backgroundColor = Colors.grey.withValues(alpha: 0.14);
      textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyInquiriesCard extends StatelessWidget {
  const _EmptyInquiriesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 38),
          SizedBox(height: 12),
          Text(
            'No inquiries found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try changing your search or filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InquiryItem {
  final String id;
  final String customerName;
  final String service;
  final String message;
  final String date;
  final DateTime createdAt;
  final String eventDate;
  final String? pax;
  final String status;
  final String avatar;
  final String replies;

  const _InquiryItem({
    required this.id,
    required this.customerName,
    required this.service,
    required this.message,
    required this.date,
    required this.createdAt,
    required this.eventDate,
    required this.pax,
    required this.status,
    required this.avatar,
    required this.replies,
  });

  factory _InquiryItem.fromModel(InquiryModel inquiry) {
    final customerName = inquiry.customerName.trim().isEmpty
        ? 'Customer'
        : inquiry.customerName.trim();
    final serviceName = inquiry.serviceName.trim().isEmpty
        ? 'Wedding Service'
        : inquiry.serviceName.trim();

    return _InquiryItem(
      id: inquiry.id,
      customerName: customerName,
      service: serviceName,
      message: inquiry.message.trim().isEmpty
          ? 'No message added.'
          : inquiry.message.trim(),
      date: DateFormat('MMM dd').format(inquiry.createdAt),
      createdAt: inquiry.createdAt,
      eventDate: 'TBC',
      pax: null,
      status: _inquiryStatusLabel(inquiry.status),
      avatar: customerName.substring(0, 1).toUpperCase(),
      replies: inquiry.status == InquiryStatus.replied
          ? 'Replied'
          : 'No replies',
    );
  }
}

String _inquiryStatusLabel(InquiryStatus status) {
  switch (status) {
    case InquiryStatus.pending:
      return 'New';
    case InquiryStatus.replied:
      return 'Replied';
    case InquiryStatus.closed:
      return 'Closed';
  }
}
