import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_data_table.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search services by title, vendor, category, or price',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.plainCollectionStream('services'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load services',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final services =
                  (snapshot.data?.docs ?? [])
                      .map((doc) => AdminCollectionItem.fromDoc(doc))
                      .where((item) {
                        final active = item.boolValue([
                          'isActive',
                        ], fallback: true);
                        return AdminHelpers.matchesValues(_search, [
                          item.stringValue(['title', 'serviceName', 'name']),
                          item.stringValue([
                            'vendorName',
                            'businessName',
                            'vendorId',
                          ]),
                          item.stringValue(['category', 'serviceCategory']),
                          item.numberValue([
                            'price',
                            'startingPrice',
                            'amount',
                          ]),
                          item.stringValue([
                            'status',
                          ], fallback: active ? 'active' : 'inactive'),
                        ]);
                      })
                      .toList()
                    ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
              if (services.isEmpty) {
                return const AdminEmptyState(
                  title: 'No services found',
                  message: 'Vendor service listings will appear here.',
                  icon: Icons.room_service_outlined,
                );
              }

              return AdminDataTable(
                minWidth: 1120,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('SERVICE')),
                  DataColumn(label: Text('VENDOR')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('PRICE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: services.asMap().entries.map((entry) {
                  final item = entry.value;
                  final title = item.stringValue([
                    'title',
                    'serviceName',
                    'name',
                  ], fallback: 'Untitled service');
                  final vendor = item.stringValue([
                    'vendorName',
                    'businessName',
                    'vendorId',
                  ], fallback: '—');
                  final category = item.stringValue([
                    'category',
                    'serviceCategory',
                  ], fallback: 'General');
                  final price = item.numberValue([
                    'price',
                    'startingPrice',
                    'amount',
                  ]);
                  final active = item.boolValue(['isActive'], fallback: true);
                  final status = item.stringValue([
                    'status',
                  ], fallback: active ? 'active' : 'inactive');

                  return DataRow(
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      DataCell(Text(title)),
                      DataCell(Text(vendor)),
                      DataCell(Text(category)),
                      DataCell(Text(AdminFormatters.currency(price))),
                      DataCell(AdminStatusChip(label: status)),
                      DataCell(
                        AdminTableActions(
                          children: [
                            AdminTableAction(
                              tooltip: active ? 'Hide' : 'Activate',
                              icon: active
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              onPressed: () =>
                                  _toggleActive(item.id, active: active),
                            ),
                            AdminTableAction(
                              tooltip: 'Delete',
                              icon: Icons.delete_outline,
                              color: AdminAppColors.danger,
                              onPressed: () => _deleteService(item.id),
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
      item.dateValue(['createdAt', 'publishedAt', 'listedAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _toggleActive(String id, {required bool active}) async {
    try {
      await widget.service.updateServiceStatus(id, !active);
      if (!mounted) return;
      AdminHelpers.showSnack(
        context,
        active ? 'Service hidden' : 'Service activated',
      );
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }

  Future<void> _deleteService(String id) async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Delete service?',
      message: 'This will permanently delete this service listing.',
      confirmText: 'Delete',
    );
    if (!confirmed) return;
    try {
      await widget.service.deleteService(id);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Service deleted');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}
