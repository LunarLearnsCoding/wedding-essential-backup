
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_enums.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class VendorBookingsScreen extends StatelessWidget {
  const VendorBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorId = FirebaseAuth.instance.currentUser?.uid;
    final bookingService = BookingService();

    if (vendorId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.getVendorBookings(vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No bookings found'),
            );
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        booking.serviceName,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        booking.customerEmail,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        booking.customerPhone,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Event Date: '
                        '${booking.eventDate.day}/'
                        '${booking.eventDate.month}/'
                        '${booking.eventDate.year}',
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            booking.status,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        child: Text(
                          _statusText(
                            booking.status,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (booking.status ==
                          BookingStatus.pending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await bookingService
                                      .confirmBooking(
                                    booking.id,
                                  );
                                },
                                child: const Text(
                                  'Approve',
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await bookingService
                                      .rejectBooking(
                                    booking.id,
                                  );
                                },
                                child: const Text(
                                  'Reject',
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (booking.status ==
                          BookingStatus.confirmed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await bookingService
                                  .completeBooking(
                                booking.id,
                              );
                            },
                            child: const Text(
                              'Mark Completed',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _statusText(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';

      case BookingStatus.confirmed:
        return 'Confirmed';

      case BookingStatus.completed:
        return 'Completed';

      case BookingStatus.rejected:
        return 'Rejected';
    }
  }

  static Color _statusColor(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;

      case BookingStatus.confirmed:
        return Colors.green;

      case BookingStatus.completed:
        return Colors.blue;

      case BookingStatus.rejected:
        return Colors.red;
    }
  }
}
