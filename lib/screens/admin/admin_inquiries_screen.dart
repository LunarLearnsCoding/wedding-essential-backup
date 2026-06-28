import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminInquiriesScreen extends StatefulWidget {
  const AdminInquiriesScreen({
    super.key,
    required this.service,
  });

  final AdminService service;

  @override
  State<AdminInquiriesScreen> createState() => _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends State<AdminInquiriesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search inquiries by customer, vendor, service, or message',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('inquiries'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load inquiries',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final inquiries = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where((item) => AdminHelpers.matchesSearch(item.data, _search))
                  .toList();

              if (inquiries.isEmpty) {
                return const AdminEmptyState(
                  title: 'No inquiries found',
                  message: 'Customer inquiries will appear here.',
                  icon: Icons.mark_email_unread_outlined,
                );
              }

              return ListView.separated(
                itemCount: inquiries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = inquiries[index];
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
                  ], fallback: 'Service inquiry');
                  final vendor = item.stringValue([
                    'vendorName',
                    'businessName',
                    'vendorId',
                  ], fallback: 'Vendor not provided');
                  final message = item.stringValue([
                    'message',
                    'description',
                    'note',
                  ], fallback: 'No message provided');
                  final status = item.stringValue(['status'], fallback: 'pending');
                  final createdAt = item.dateValue(['createdAt']);

                  return AdminRecordCard(
                    leadingIcon: Icons.mark_email_unread_outlined,
                    title: serviceTitle,
                    subtitle: message,
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(icon: Icons.person_outline, label: customer),
                      AdminMetaPill(icon: Icons.storefront_outlined, label: vendor),
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.dateTime(createdAt),
                      ),
                    ],
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => _changeStatus(item.id, 'in_progress'),
                        icon: const Icon(Icons.timelapse_outlined),
                        label: const Text('In progress'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _changeStatus(item.id, 'resolved'),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Resolve'),
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
      await widget.service.updateInquiryStatus(id, status);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Inquiry marked as $status');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}
