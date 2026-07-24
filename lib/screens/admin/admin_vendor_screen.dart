import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_data_table.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_helpers.dart';
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
          hintText: 'Search vendors by business, owner, category, or status',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.plainCollectionStream('vendors'),
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

              final vendors =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => AdminCollectionItem.fromDoc(doc))
                      .where((item) {
                        return AdminHelpers.matchesValues(_search, [
                          item.stringValue([
                            'businessName',
                            'companyName',
                            'vendorName',
                            'name',
                          ]),
                          item.stringValue([
                            'ownerName',
                            'contactName',
                            'fullName',
                            'name',
                          ]),
                          item.stringValue(['email']),
                          item.stringValue(['phone', 'phoneNumber']),
                          item.stringValue([
                            'category',
                            'serviceCategory',
                            'type',
                          ]),
                          item.stringValue(
                            ['status', 'approvalStatus'],
                            fallback: item.boolValue(['isApproved'])
                                ? 'approved'
                                : 'pending',
                          ),
                        ]);
                      })
                      .toList()
                    ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
              if (vendors.isEmpty) {
                return const AdminEmptyState(
                  title: 'No vendors found',
                  message: 'Vendor registration requests will appear here.',
                  icon: Icons.storefront_outlined,
                );
              }

              return AdminDataTable(
                minWidth: 1120,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('BUSINESS')),
                  DataColumn(label: Text('OWNER')),
                  DataColumn(label: Text('CONTACT')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: vendors.asMap().entries.map((entry) {
                  final item = entry.value;
                  final business = item.stringValue([
                    'businessName',
                    'companyName',
                    'vendorName',
                    'name',
                  ], fallback: 'Unnamed vendor');
                  final owner = item.stringValue([
                    'ownerName',
                    'contactName',
                    'fullName',
                    'name',
                  ], fallback: '—');
                  final email = item.stringValue(['email'], fallback: '—');
                  final phone = item.stringValue([
                    'phone',
                    'phoneNumber',
                  ], fallback: '—');
                  final category = item.stringValue([
                    'category',
                    'serviceCategory',
                    'type',
                  ], fallback: 'General');
                  final status = item.stringValue(
                    ['status', 'approvalStatus'],
                    fallback: item.boolValue(['isApproved'])
                        ? 'approved'
                        : 'pending',
                  );

                  return DataRow(
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      DataCell(Text(business)),
                      DataCell(Text(owner)),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Text(email), Text(phone)],
                        ),
                      ),
                      DataCell(Text(category)),
                      DataCell(AdminStatusChip(label: status)),
                      DataCell(
                        AdminTableActions(
                          children: [
                            AdminTableAction(
                              tooltip: 'Approve',
                              icon: Icons.check_circle_outline,
                              color: AdminAppColors.success,
                              onPressed: () => _updateStatus(item.id, true),
                            ),
                            AdminTableAction(
                              tooltip: 'Reject',
                              icon: Icons.cancel_outlined,
                              color: AdminAppColors.warning,
                              onPressed: () => _updateStatus(item.id, false),
                            ),
                            AdminTableAction(
                              tooltip: 'Delete',
                              icon: Icons.delete_outline,
                              color: AdminAppColors.danger,
                              onPressed: () => _deleteVendor(item.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  DateTime _createdAt(AdminCollectionItem item) =>
      item.dateValue(['createdAt', 'registeredAt', 'joinedAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _updateStatus(String id, bool approve) async {
    try {
      if (approve) {
        await widget.service.approveVendor(id);
      } else {
        await widget.service.rejectVendor(id);
      }
      if (!mounted) return;
      AdminHelpers.showSnack(
        context,
        approve ? 'Vendor approved' : 'Vendor rejected',
      );
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }

  Future<void> _deleteVendor(String id) async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Delete vendor?',
      message:
          'This permanently deletes the Firebase Authentication account and '
          'its vendor records.',
      confirmText: 'Delete',
    );
    if (!confirmed) return;
    try {
      await widget.service.deleteUserData(id);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Vendor deleted');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}
