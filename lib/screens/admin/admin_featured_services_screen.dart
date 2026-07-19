import 'package:flutter/material.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_data_table.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';

class AdminFeaturedVendorsScreen extends StatefulWidget {
  const AdminFeaturedVendorsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminFeaturedVendorsScreen> createState() =>
      _AdminFeaturedVendorsScreenState();
}

class _AdminFeaturedVendorsScreenState
    extends State<AdminFeaturedVendorsScreen> {
  final Set<String> _clearingExpired = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.service.plainCollectionStream('vendors'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AdminEmptyState(
            title: 'Unable to load featured vendors',
            message: snapshot.error.toString(),
            icon: Icons.error_outline,
          );
        }

        final vendors = (snapshot.data?.docs ?? [])
            .map(AdminCollectionItem.fromDoc)
            .toList();
        final now = DateTime.now();
        final expired = vendors.where((vendor) {
          final until = vendor.dateValue(['featuredUntil']);
          return vendor.boolValue(['isFeatured']) &&
              until != null &&
              !until.isAfter(now);
        }).toList();
        _scheduleExpiredCleanup(expired);

        final featured =
            vendors.where((vendor) {
              if (!vendor.boolValue(['isFeatured'])) return false;
              final until = vendor.dateValue(['featuredUntil']);
              return until == null || until.isAfter(now);
            }).toList()..sort((a, b) {
              final aUntil = a.dateValue(['featuredUntil']);
              final bUntil = b.dateValue(['featuredUntil']);
              if (aUntil == null) return 1;
              if (bUntil == null) return -1;
              return aUntil.compareTo(bUntil);
            });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                const description = Text(
                  'Approved, unexpired featured vendors appear on the customer dashboard.',
                  style: TextStyle(color: AdminAppColors.textSecondary),
                );
                final button = FilledButton.icon(
                  onPressed: () => _showAddDialog(vendors),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Featured Vendor'),
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [description, const SizedBox(height: 12), button],
                  );
                }
                return Row(
                  children: [
                    const Expanded(child: description),
                    const SizedBox(width: 16),
                    button,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: featured.isEmpty
                  ? const AdminEmptyState(
                      title: 'No featured vendors',
                      message:
                          'Add an approved vendor and choose how long they should be featured.',
                      icon: Icons.star_border_rounded,
                    )
                  : AdminDataTable(
                      minWidth: 780,
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('VENDOR')),
                        DataColumn(label: Text('CATEGORY')),
                        DataColumn(label: Text('FEATURED UNTIL')),
                        DataColumn(label: Text('TIME LEFT')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: featured.asMap().entries.map((entry) {
                        final vendor = entry.value;
                        final until = vendor.dateValue(['featuredUntil']);
                        return DataRow(
                          cells: [
                            DataCell(Text('${entry.key + 1}')),
                            DataCell(
                              Text(
                                vendor.stringValue([
                                  'businessName',
                                  'name',
                                ], fallback: 'Unnamed vendor'),
                              ),
                            ),
                            DataCell(
                              Text(
                                vendor.stringValue([
                                  'category',
                                ], fallback: 'General'),
                              ),
                            ),
                            DataCell(
                              Text(
                                until == null
                                    ? 'No expiry (legacy)'
                                    : AdminFormatters.date(until),
                              ),
                            ),
                            DataCell(Text(_timeLeft(until, now))),
                            DataCell(
                              AdminTableAction(
                                tooltip: 'Remove featured vendor',
                                icon: Icons.delete_outline,
                                color: AdminAppColors.danger,
                                onPressed: () => _remove(vendor),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _scheduleExpiredCleanup(List<AdminCollectionItem> expired) {
    for (final vendor in expired) {
      if (!_clearingExpired.add(vendor.id)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await widget.service.removeFeaturedVendor(vendor.id);
        } finally {
          _clearingExpired.remove(vendor.id);
        }
      });
    }
  }

  Future<void> _showAddDialog(List<AdminCollectionItem> vendors) async {
    final approved =
        vendors.where((vendor) {
          final status = vendor.stringValue([
            'approvalStatus',
            'status',
          ], fallback: 'pending').toLowerCase();
          return vendor.boolValue(['isApproved']) || status == 'approved';
        }).toList()..sort(
          (a, b) => a
              .stringValue(['businessName', 'name'])
              .compareTo(b.stringValue(['businessName', 'name'])),
        );
    if (approved.isEmpty) {
      AdminHelpers.showSnack(
        context,
        'No approved vendors are available to feature.',
        isError: true,
      );
      return;
    }

    final selection = await showDialog<_FeaturedSelection>(
      context: context,
      builder: (_) => _AddFeaturedVendorDialog(vendors: approved),
    );
    if (!mounted || selection == null) return;
    try {
      await widget.service.featureVendorUntil(
        selection.vendorId,
        DateTime.now().add(Duration(days: selection.days)),
      );
      if (!mounted) return;
      AdminHelpers.showSnack(
        context,
        'Vendor featured for ${selection.days} days.',
      );
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }

  Future<void> _remove(AdminCollectionItem vendor) async {
    final confirmed = await AdminHelpers.confirm(
      context,
      title: 'Remove featured vendor?',
      message: 'This vendor will stop appearing in Featured Vendors.',
      confirmText: 'Remove',
    );
    if (!mounted || !confirmed) return;
    try {
      await widget.service.removeFeaturedVendor(vendor.id);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Vendor removed from featured.');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }

  String _timeLeft(DateTime? until, DateTime now) {
    if (until == null) return 'No expiry';
    final difference = until.difference(now);
    if (difference.inDays >= 1) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    }
    final hours = difference.inHours.clamp(0, 23);
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }
}

class _FeaturedSelection {
  const _FeaturedSelection({required this.vendorId, required this.days});

  final String vendorId;
  final int days;
}

class _AddFeaturedVendorDialog extends StatefulWidget {
  const _AddFeaturedVendorDialog({required this.vendors});

  final List<AdminCollectionItem> vendors;

  @override
  State<_AddFeaturedVendorDialog> createState() =>
      _AddFeaturedVendorDialogState();
}

class _AddFeaturedVendorDialogState extends State<_AddFeaturedVendorDialog> {
  late String _vendorId;
  int _days = 7;

  @override
  void initState() {
    super.initState();
    _vendorId = widget.vendors.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add featured vendor'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _vendorId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Vendor'),
              items: widget.vendors.map((vendor) {
                final name = vendor.stringValue([
                  'businessName',
                  'name',
                ], fallback: 'Unnamed vendor');
                final category = vendor.stringValue([
                  'category',
                ], fallback: 'General');
                return DropdownMenuItem(
                  value: vendor.id,
                  child: Text(
                    '$name — $category',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _vendorId = value ?? _vendorId),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _days,
              decoration: const InputDecoration(labelText: 'Featured period'),
              items: const [1, 3, 7, 14, 30]
                  .map(
                    (days) => DropdownMenuItem(
                      value: days,
                      child: Text('$days ${days == 1 ? 'day' : 'days'}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _days = value ?? 7),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _FeaturedSelection(vendorId: _vendorId, days: _days),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
