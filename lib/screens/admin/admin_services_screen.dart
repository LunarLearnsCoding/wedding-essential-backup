import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
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
            stream: widget.service.collectionStream('services'),
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

              final docs = snapshot.data?.docs ?? [];
              final services = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where(
                    (item) => AdminHelpers.matchesSearch(item.data, _search),
                  )
                  .toList();

              if (services.isEmpty) {
                return const AdminEmptyState(
                  title: 'No services found',
                  message: 'Vendor service listings will appear here.',
                  icon: Icons.room_service_outlined,
                );
              }

              return ListView.separated(
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = services[index];
                  final title = item.stringValue([
                    'title',
                    'serviceName',
                    'name',
                  ], fallback: 'Untitled service');
                  final vendor = item.stringValue([
                    'vendorName',
                    'businessName',
                    'vendorId',
                  ], fallback: 'Vendor not provided');
                  final category = item.stringValue([
                    'category',
                    'serviceCategory',
                  ], fallback: 'General');
                  final price = item.numberValue([
                    'price',
                    'startingPrice',
                    'amount',
                  ]);
                  final isActive = item.boolValue(['isActive'], fallback: true);
                  final status = item.stringValue([
                    'status',
                  ], fallback: isActive ? 'active' : 'inactive');
                  final createdAt = item.dateValue(['createdAt']);

                  return AdminRecordCard(
                    leadingIcon: Icons.room_service_outlined,
                    title: title,
                    subtitle: vendor,
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(
                        icon: Icons.category_outlined,
                        label: category,
                      ),
                      AdminMetaPill(
                        icon: Icons.payments_outlined,
                        label: AdminFormatters.currency(price),
                      ),
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.date(createdAt),
                      ),
                    ],
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await widget.service.updateServiceStatus(
                              item.id,
                              !isActive,
                            );
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              isActive ? 'Service hidden' : 'Service activated',
                            );
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: Icon(
                          isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        label: Text(isActive ? 'Hide' : 'Activate'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await AdminHelpers.confirm(
                            context,
                            title: 'Delete service?',
                            message:
                                'This will permanently delete this service listing.',
                            confirmText: 'Delete',
                          );
                          if (!confirmed) return;
                          try {
                            await widget.service.deleteDocument(
                              'services',
                              item.id,
                            );
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'Service deleted');
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
