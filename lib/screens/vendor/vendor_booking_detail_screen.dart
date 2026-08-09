import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_enums.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

/// Displays the vendor booking detail page and coordinates the actions available on it.
class VendorBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const VendorBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<VendorBookingDetailScreen> createState() =>
      _VendorBookingDetailScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _VendorBookingDetailScreenState extends State<VendorBookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  late Future<BookingModel?> _bookingFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _bookingService.getBooking(widget.bookingId);
  }

  /// Loads booking and updates the visible state.
  void _loadBooking() {
    setState(() {
      _bookingFuture = _bookingService.getBooking(widget.bookingId);
    });
  }

  /// Applies the requested status change and refreshes state.
  Future<void> _updateStatus(BookingStatus newStatus) async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _bookingService.updateBookingStatus(
        bookingId: widget.bookingId,
        status: newStatus,
      );

      final refreshedBooking = await _bookingService.getBooking(
        widget.bookingId,
      );

      if (!mounted) return;

      setState(() {
        _bookingFuture = Future.value(refreshedBooking);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking marked as ${_bookingStatusLabel(newStatus)}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<BookingModel?>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageState(
              title: 'Failed to load booking',
              message: snapshot.error.toString(),
              onRetry: _loadBooking,
            );
          }

          final booking = snapshot.data;

          if (booking == null) {
            return _MessageState(
              title: 'Booking not found',
              message: 'This booking may have been removed.',
              onRetry: _loadBooking,
            );
          }

          final status = _bookingStatusLabel(booking.status);
          final isCancelled = booking.status == BookingStatus.cancelled;

          return Column(
            children: [
              _BookingDetailHeader(bookingId: booking.id, status: status),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookingInfoCard(booking: booking),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Update Status'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatusButton(
                            label: 'Pending',
                            icon: Icons.schedule_outlined,
                            color: Colors.orange,
                            isSelected: status == 'Pending',
                            onTap: _isUpdatingStatus || isCancelled
                                ? null
                                : () {
                                    _updateStatus(BookingStatus.pending);
                                  },
                          ),
                          _StatusButton(
                            label: 'Confirmed',
                            icon: Icons.check_circle_outline,
                            color: AppColors.primary,
                            isSelected: status == 'Confirmed',
                            onTap: _isUpdatingStatus || isCancelled
                                ? null
                                : () {
                                    _updateStatus(BookingStatus.confirmed);
                                  },
                          ),
                          _StatusButton(
                            label: 'Completed',
                            icon: Icons.done_all_outlined,
                            color: Colors.green,
                            isSelected: status == 'Completed',
                            onTap: _isUpdatingStatus || isCancelled
                                ? null
                                : () {
                                    _updateStatus(BookingStatus.completed);
                                  },
                          ),
                          _StatusButton(
                            label: 'Rejected',
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                            isSelected: status == 'Rejected',
                            onTap: _isUpdatingStatus || isCancelled
                                ? null
                                : () {
                                    _updateStatus(BookingStatus.rejected);
                                  },
                          ),
                        ],
                      ),
                      if (_isUpdatingStatus) const SizedBox(height: 14),
                      if (_isUpdatingStatus)
                        const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 24),
                      const _SectionHeader(title: 'Suggested Next Steps'),
                      const SizedBox(height: 14),
                      const _NextStepsCard(),
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

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MessageState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _BookingDetailHeader(bookingId: '', status: 'Unavailable'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
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
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders the reusable booking detail header UI component.
class _BookingDetailHeader extends StatelessWidget {
  final String bookingId;
  final String status;

  const _BookingDetailHeader({required this.bookingId, required this.status});

  @override
  Widget build(BuildContext context) {
    final bookingLabel = bookingId.isEmpty ? 'Booking unavailable' : bookingId;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking ID: $bookingLabel',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Booking Details',
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

/// Renders the reusable booking info card UI component.
class _BookingInfoCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final customerName = _displayValue(booking.customerName, 'Customer');
    final serviceName = _displayValue(booking.serviceName, 'Wedding Service');
    final createdDate = DateFormat('dd MMM yyyy').format(booking.createdAt);
    final eventDate = DateFormat('dd MMM yyyy').format(booking.eventDate);
    final eventTime = DateFormat('h:mm a').format(booking.eventTime);
    final price = booking.servicePrice <= 0
        ? 'Not provided'
        : 'Rs. ${NumberFormat('#,##0').format(booking.servicePrice)}';
    final phone = _displayValue(booking.customerPhone, 'Not provided');
    final email = _displayValue(booking.customerEmail, 'Not provided');
    final note = _displayValue(booking.note, 'No notes added.');

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
                radius: 27,
                backgroundColor: AppColors.selectedSurface,
                child: Text(
                  customerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
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
                      'Booked on $createdDate',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _DetailRow(
            icon: Icons.business_center_outlined,
            label: 'Service',
            value: serviceName,
          ),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Event Date',
            value: eventDate,
          ),
          _DetailRow(
            icon: Icons.access_time_outlined,
            label: 'Event Time',
            value: eventTime,
          ),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Amount',
            value: price,
          ),
          _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
          _DetailRow(icon: Icons.email_outlined, label: 'Email', value: email),
          _DetailRow(
            icon: Icons.info_outline,
            label: 'Status',
            value: _bookingStatusLabel(booking.status),
          ),
          const SizedBox(height: 10),
          const Text(
            'Notes',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable detail row UI component.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.selectedSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable section header UI component.
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

/// Renders the reusable status button UI component.
class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.14) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the reusable next steps card UI component.
class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _TodoRow(text: 'Confirm final guest count and event timing.'),
          _TodoRow(text: 'Share vendor checklist with the customer.'),
          _TodoRow(text: 'Prepare quotation or payment confirmation.'),
        ],
      ),
    );
  }
}

/// Renders the reusable todo row UI component.
class _TodoRow extends StatelessWidget {
  final String text;

  const _TodoRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.35,
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
      backgroundColor = Colors.orange.withValues(alpha: 0.20);
      textColor = Colors.white;
    } else if (status == 'Confirmed') {
      backgroundColor = Colors.white.withValues(alpha: 0.18);
      textColor = Colors.white;
    } else if (status == 'Completed') {
      backgroundColor = Colors.green.withValues(alpha: 0.20);
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.red.withValues(alpha: 0.20);
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

String _displayValue(String value, String fallback) {
  final text = value.trim();

  if (text.isEmpty) {
    return fallback;
  }

  return text;
}
