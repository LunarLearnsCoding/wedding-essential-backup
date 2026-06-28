import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({
    super.key,
    required this.service,
  });

  final AdminService service;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search bookings by customer, vendor, service, or status',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('bookings'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load bookings',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final bookings = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where((item) => AdminHelpers.matchesSearch(item.data, _search))
                  .toList();

              if (bookings.isEmpty) {
                return const AdminEmptyState(
                  title: 'No bookings found',
                  message: 'Customer bookings will appear here.',
                  icon: Icons.calendar_month_outlined,
                );
              }

              return ListView.separated(
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = bookings[index];
                  final customer = item.stringValue([
                    'customerName',
                    'userName',
                    'name',
                    'customerId',
                  ], fallback: 'Unknown customer');
                  final serviceTitle = item.stringValue([
                    'serviceTitle',
                    'serviceName',
                    'title',
                    'serviceId',
                  ], fallback: 'Wedding service');
                  final vendor = item.stringValue([
                    'vendorName',
                    'businessName',
                    'vendorId',
                  ], fallback: 'Vendor not provided');
                  final status = item.stringValue(['status'], fallback: 'pending');
                  final amount = item.numberValue([
                    'totalAmount',
                    'amount',
                    'price',
                  ]);
                  final bookingDate = item.dateValue([
                    'bookingDate',
                    'eventDate',
                    'date',
                    'createdAt',
                  ]);

                  return AdminRecordCard(
                    leadingIcon: Icons.event_available_outlined,
                    title: serviceTitle,
                    subtitle: '$customer • $vendor',
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.dateTime(bookingDate),
                      ),
                      AdminMetaPill(
                        icon: Icons.payments_outlined,
                        label: AdminFormatters.currency(amount),
                      ),
                    ],
                    actions: [
                      _StatusButton(
                        label: 'Confirm',
                        icon: Icons.check_circle_outline,
                        onPressed: () => _changeStatus(item.id, 'confirmed'),
                      ),
                      _StatusButton(
                        label: 'Complete',
                        icon: Icons.done_all_outlined,
                        onPressed: () => _changeStatus(item.id, 'completed'),
                      ),
                      _StatusButton(
                        label: 'Cancel',
                        icon: Icons.cancel_outlined,
                        onPressed: () => _changeStatus(item.id, 'cancelled'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _changeStatus(String id, String status) async {
    try {
      await widget.service.updateBookingStatus(id, status);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Booking marked as $status');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
