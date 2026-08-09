import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import '../../models/app_enums.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'vendor_booking_detail_screen.dart';

/// Displays the vendor bookings page and coordinates the actions available on it.
class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  final BookingService _bookingService = BookingService();
  String _selectedFilter = 'All';

  List<_BookingItem> _filteredBookings(List<_BookingItem> bookings) {
    if (_selectedFilter == 'All') {
      return bookings;
    }

    return bookings.where((booking) {
      return booking.status == _selectedFilter;
    }).toList();
  }

  int _pendingCount(List<_BookingItem> bookings) {
    return bookings.where((booking) => booking.status == 'Pending').length;
  }

  Future<void> _changeBookingStatus(_BookingItem booking, String status) async {
    try {
      if (status == 'Confirmed') {
        await _bookingService.confirmBooking(booking.id);
      } else if (status == 'Rejected') {
        await _bookingService.rejectBooking(booking.id);
      } else if (status == 'Completed') {
        await _bookingService.completeBooking(booking.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getVendorBookings(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load bookings: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final models = List<BookingModel>.from(snapshot.data ?? const [])
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final bookings = models.map(_BookingItem.fromModel).toList();
          final filteredBookings = _filteredBookings(bookings);

          return Column(
            children: [
              _BookingsHeader(pendingCount: _pendingCount(bookings)),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookingFilterTabs(
                        selectedFilter: _selectedFilter,
                        bookings: bookings,
                        onChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                      ),

                      const SizedBox(height: 28),

                      _SectionHeader(
                        title: 'Customer Bookings',
                        actionText: '${filteredBookings.length} found',
                      ),

                      const SizedBox(height: 14),

                      if (filteredBookings.isEmpty)
                        const _EmptyBookingsCard()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredBookings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final booking = filteredBookings[index];

                            return _BookingCard(
                              booking: booking,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VendorBookingDetailScreen(
                                      bookingId: booking.id,
                                    ),
                                  ),
                                );
                              },
                              onConfirm: booking.status == 'Pending'
                                  ? () {
                                      _changeBookingStatus(
                                        booking,
                                        'Confirmed',
                                      );
                                    }
                                  : null,
                              onCancel: booking.status == 'Pending'
                                  ? () {
                                      _changeBookingStatus(booking, 'Rejected');
                                    }
                                  : null,
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
      bottomNavigationBar: const VendorBottomNav(currentIndex: 2),
    );
  }
}

/// Renders the reusable bookings header UI component.
class _BookingsHeader extends StatelessWidget {
  final int pendingCount;

  const _BookingsHeader({required this.pendingCount});

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
                  'Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                '$pendingCount pending',
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

/// Renders the reusable booking filter tabs UI component.
class _BookingFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final List<_BookingItem> bookings;
  final ValueChanged<String> onChanged;

  const _BookingFilterTabs({
    required this.selectedFilter,
    required this.bookings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      'All',
      'Pending',
      'Confirmed',
      'Rejected',
      'Completed',
      'Cancelled',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          final count = filter == 'All'
              ? bookings.length
              : bookings.where((item) => item.status == filter).length;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                onChanged(filter);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  '$filter $count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Renders the reusable section header UI component.
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

/// Renders the reusable booking card UI component.
class _BookingCard extends StatelessWidget {
  final _BookingItem booking;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.onTap,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == 'Pending';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(text: booking.avatar),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.customerName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (booking.customerEmail.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    booking.customerEmail,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Align(
                            alignment: Alignment.topRight,
                            child: _StatusBadge(status: booking.status),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _SmallInfoRow(
                        icon: Icons.business_center_outlined,
                        text: booking.service,
                      ),

                      _SmallInfoRow(
                        icon: Icons.calendar_today_outlined,
                        text: booking.eventDate,
                      ),

                      _SmallInfoRow(
                        icon: Icons.payments_outlined,
                        text: booking.amount,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isPending) const SizedBox(height: 14),

            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: SizedBox(
                      height: 46,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders the reusable avatar UI component.
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

/// Renders the reusable small info row UI component.
class _SmallInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable status badge UI component.
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (status == 'Pending') {
      backgroundColor = Colors.orange.withValues(alpha: 0.12);
      textColor = Colors.orange;
    } else if (status == 'Confirmed') {
      backgroundColor = AppColors.primary.withValues(alpha: 0.12);
      textColor = AppColors.primary;
    } else if (status == 'Completed') {
      backgroundColor = Colors.green.withValues(alpha: 0.12);
      textColor = Colors.green;
    } else {
      backgroundColor = Colors.red.withValues(alpha: 0.12);
      textColor = Colors.red;
    }

    return Container(
      height: 28,
      alignment: Alignment.center,
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

/// Renders the reusable empty bookings card UI component.
class _EmptyBookingsCard extends StatelessWidget {
  const _EmptyBookingsCard();

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
          Icon(
            Icons.calendar_month_outlined,
            color: AppColors.primary,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'No bookings found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Bookings matching this filter will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Groups the data and behavior required by the booking item component.
class _BookingItem {
  final String id;
  final String customerName;
  final String customerEmail;
  final String service;
  final String eventDate;
  final String amount;
  final String status;
  final String avatar;

  const _BookingItem({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.service,
    required this.eventDate,
    required this.amount,
    required this.status,
    required this.avatar,
  });

  factory _BookingItem.fromModel(BookingModel booking) {
    final customerName = booking.customerName.trim().isEmpty
        ? 'Customer'
        : booking.customerName.trim();
    final serviceName = booking.serviceName.trim().isEmpty
        ? 'Wedding Service'
        : booking.serviceName.trim();

    return _BookingItem(
      id: booking.id,
      customerName: customerName,
      customerEmail: booking.customerEmail.trim(),
      service: serviceName,
      eventDate: DateFormat('dd MMM yyyy').format(booking.eventDate),
      amount: 'Rs. ${NumberFormat('#,##0').format(booking.servicePrice)}',
      status: _bookingStatusLabel(booking.status),
      avatar: customerName.substring(0, 1).toUpperCase(),
    );
  }
}

String _bookingStatusLabel(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return 'Pending';
    case BookingStatus.confirmed:
      return 'Confirmed';
    case BookingStatus.rejected:
      return 'Rejected';
    case BookingStatus.completed:
      return 'Completed';
    case BookingStatus.cancelled:
      return 'Cancelled';
  }
}
