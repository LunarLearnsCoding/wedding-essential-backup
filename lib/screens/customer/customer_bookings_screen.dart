import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../models/app_enums.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';

class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({super.key});

  static final BookingService _bookingService = BookingService();
  static final ReviewService _reviewService = ReviewService();

  Future<void> _cancelBooking(
    BuildContext context,
    BookingModel booking,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking?'),
          content: const Text(
            'Are you sure you want to cancel this booking request?',
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
      await _bookingService.cancelBooking(booking);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel booking: $error')),
      );
    }
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    BookingModel booking,
  ) async {
    final screenContext = context;
    final reviewController = TextEditingController();
    var selectedRating = 5;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitReview() async {
              if (isSaving) return;

              final reviewText = reviewController.text.trim();
              if (reviewText.length < 5 || reviewText.length > 500) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Review text must be between 5 and 500 characters.',
                    ),
                  ),
                );
                return;
              }

              setDialogState(() => isSaving = true);
              try {
                await _reviewService.submitBookingReview(
                  booking: booking,
                  rating: selectedRating.toDouble(),
                  reviewText: reviewText,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!screenContext.mounted) return;
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  const SnackBar(
                    content: Text('Review submitted successfully'),
                  ),
                );
              } catch (error) {
                if (!dialogContext.mounted) return;
                setDialogState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_reviewErrorMessage(error))),
                );
              }
            }

            return AlertDialog(
              title: const Text('Write Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName.trim().isEmpty
                          ? 'Wedding Service'
                          : booking.serviceName.trim(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starRating = index + 1;
                        return IconButton(
                          onPressed: isSaving
                              ? null
                              : () => setDialogState(
                                  () => selectedRating = starRating,
                                ),
                          icon: Icon(
                            starRating <= selectedRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reviewController,
                      enabled: !isSaving,
                      maxLines: 5,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Your Review',
                        hintText: 'Share your experience with this service.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submitReview,
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );

    reviewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>().bookings;

    if (bookings.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('My Bookings')),
        body: const _EmptyBookingsView(),
      );
    }

    final sortedBookings = List<BookingModel>.from(bookings)
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Bookings')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        itemCount: sortedBookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final booking = sortedBookings[index];
          return _BookingCard(
            booking: booking,
            onCancel: () => _cancelBooking(context, booking),
            onReview: () => _showReviewDialog(context, booking),
          );
        },
      ),
    );
  }
}

class _EmptyBookingsView extends StatelessWidget {
  const _EmptyBookingsView();

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
                Icons.calendar_month_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No bookings yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your booking requests will appear here once you book a wedding service.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  const _BookingCard({
    required this.booking,
    required this.onCancel,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = booking.serviceName.isNotEmpty
        ? booking.serviceName
        : 'Wedding Service';
    final vendorName = booking.vendorName.isNotEmpty
        ? booking.vendorName
        : 'Vendor';

    final requestedDate = DateFormat('MMM dd, yyyy').format(booking.eventDate);
    final requestedTime = DateFormat('hh:mm a').format(booking.eventDate);
    final statusString = enumToString(booking.status).toLowerCase();

    final price = booking.servicePrice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
                  Icons.event_available_outlined,
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
              _StatusBadge(status: statusString),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  icon: Icons.calendar_month_outlined,
                  title: 'Date',
                  value: requestedDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  icon: Icons.access_time_outlined,
                  title: 'Time',
                  value: requestedTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _MiniInfoBox(
            icon: Icons.payments_outlined,
            title: 'Estimated Price',
            value: price <= 0
                ? 'Not provided'
                : 'Rs. ${price.toStringAsFixed(0)}',
          ),

          if (statusString == 'pending') ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel Request'),
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
          if (booking.status == BookingStatus.completed) ...[
            const SizedBox(height: 18),
            StreamBuilder<bool>(
              stream: CustomerBookingsScreen._reviewService.hasReviewForBooking(
                booking.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final hasReview = snapshot.data ?? false;
                return SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: hasReview
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Reviewed'),
                        )
                      : ElevatedButton.icon(
                          onPressed: onReview,
                          icon: const Icon(Icons.rate_review_outlined),
                          label: const Text('Write Review'),
                        ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

String _reviewErrorMessage(Object error) {
  if (error is StateError) return error.message.toString();
  return 'Failed to submit review: $error';
}

class _MiniInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniInfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() + status.substring(1);

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'accepted':
      case 'confirmed':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'rejected':
      case 'cancelled':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'completed':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
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
