import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('customerId', isEqualTo: user.uid)
        .snapshots();
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
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
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel booking: $error'),
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
          title: const Text('My Bookings'),
        ),
        body: const Center(
          child: Text('Please login to view your bookings.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _bookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final bookings = snapshot.data?.docs ?? [];

          if (bookings.isEmpty) {
            return const _EmptyBookingsView();
          }

          bookings.sort((a, b) {
            final aDate = _dateFromValue(a.data()['requestedDateTime']);
            final bDate = _dateFromValue(b.data()['requestedDateTime']);

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;

            return bDate.compareTo(aDate);
          });

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final data = bookingDoc.data();

              return _BookingCard(
                bookingId: bookingDoc.id,
                bookingData: data,
                onCancel: () => _cancelBooking(context, bookingDoc.id),
              );
            },
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

class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final VoidCallback onCancel;

  const _BookingCard({
    required this.bookingId,
    required this.bookingData,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = _stringValue(
      bookingData,
      'serviceName',
      fallback: 'Wedding Service',
    );

    final vendorName = _stringValue(
      bookingData,
      'vendorName',
      fallback: 'Vendor',
    );

    final requestedDate = _stringValue(bookingData, 'requestedDate');
    final requestedTime = _stringValue(bookingData, 'requestedTime');
    final status = _stringValue(
      bookingData,
      'status',
      fallback: 'pending',
    ).toLowerCase();

    final note = _stringValue(bookingData, 'note');
    final price = _doubleValue(bookingData, 'price');

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
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  icon: Icons.calendar_month_outlined,
                  title: 'Date',
                  value: requestedDate.isEmpty ? 'Not set' : requestedDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  icon: Icons.access_time_outlined,
                  title: 'Time',
                  value: requestedTime.isEmpty ? 'Not set' : requestedTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _MiniInfoBox(
            icon: Icons.payments_outlined,
            title: 'Estimated Price',
            value: price <= 0 ? 'Not provided' : 'Rs. ${price.toStringAsFixed(0)}',
          ),

          if (note.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Your Note',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              note,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
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
        ],
      ),
    );
  }
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
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primary,
          ),
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

double _doubleValue(Map<String, dynamic> data, String key) {
  final value = data[key];

  if (value is num) return value.toDouble();

  return double.tryParse(value.toString()) ?? 0;
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