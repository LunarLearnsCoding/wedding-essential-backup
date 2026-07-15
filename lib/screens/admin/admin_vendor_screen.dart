import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminVendorsScreen extends StatefulWidget {
  const AdminVendorsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminVendorsScreen> createState() => _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends State<AdminVendorsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText:
              'Search vendors by business name, owner, category, or status',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('vendors'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load vendors',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final vendors = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where(
                    (item) => AdminHelpers.matchesSearch(item.data, _search),
                  )
                  .toList();

              if (vendors.isEmpty) {
                return const AdminEmptyState(
                  title: 'No vendors found',
                  message: 'Vendor registration requests will appear here.',
                  icon: Icons.storefront_outlined,
                );
              }

              return ListView.separated(
                itemCount: vendors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = vendors[index];
                  final businessName = item.stringValue([
                    'businessName',
                    'companyName',
                    'vendorName',
                    'name',
                  ], fallback: 'Unnamed vendor');
                  final owner = item.stringValue([
                    'ownerName',
                    'contactName',
                    'fullName',
                  ], fallback: 'Owner not provided');
                  final category = item.stringValue([
                    'category',
                    'serviceCategory',
                    'type',
                  ], fallback: 'General');
                  final email = item.stringValue(['email']);
                  final phone = item.stringValue(['phone', 'phoneNumber']);
                  final status = item.stringValue(
                    ['status', 'approvalStatus'],
                    fallback: item.boolValue(['isApproved'])
                        ? 'approved'
                        : 'pending',
                  );
                  final createdAt = item.dateValue([
                    'createdAt',
                    'registeredAt',
                  ]);

                  return AdminRecordCard(
                    leadingIcon: Icons.storefront_outlined,
                    title: businessName,
                    subtitle: '$owner • $email',
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(
                        icon: Icons.category_outlined,
                        label: category,
                      ),
                      AdminMetaPill(icon: Icons.phone_outlined, label: phone),
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.date(createdAt),
                      ),
                    ],
                    actions: [
                      FilledButton.icon(
                        onPressed: () async {
                          try {
                            await widget.service.approveVendor(item.id);
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'Vendor approved');
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await widget.service.rejectVendor(item.id);
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'Vendor rejected');
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Reject'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await AdminHelpers.confirm(
                            context,
                            title: 'Delete vendor?',
                            message:
                                'This will permanently delete this vendor document.',
                            confirmText: 'Delete',
                          );
                          if (!confirmed) return;
                          try {
                            await widget.service.deleteDocument(
                              'vendors',
                              item.id,
                            );
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'Vendor deleted');
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
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
}
