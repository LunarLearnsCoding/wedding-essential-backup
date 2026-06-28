import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({
    super.key,
    required this.service,
  });

  final AdminService service;

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search reviews by customer, vendor, service, or comment',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('reviews'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load reviews',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final reviews = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where((item) => AdminHelpers.matchesSearch(item.data, _search))
                  .toList();

              if (reviews.isEmpty) {
                return const AdminEmptyState(
                  title: 'No reviews found',
                  message: 'Customer reviews will appear here.',
                  icon: Icons.star_border_rounded,
                );
              }

              return ListView.separated(
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = reviews[index];
                  final customer = item.stringValue([
                    'customerName',
                    'userName',
                    'name',
                    'userId',
                  ], fallback: 'Anonymous customer');
                  final vendor = item.stringValue([
                    'vendorName',
                    'businessName',
                    'vendorId',
                  ], fallback: 'Vendor not provided');
                  final serviceTitle = item.stringValue([
                    'serviceTitle',
                    'serviceName',
                    'title',
                  ], fallback: 'Service review');
                  final comment = item.stringValue([
                    'comment',
                    'review',
                    'message',
                  ], fallback: 'No comment');
                  final rating = item.numberValue(['rating', 'stars']);
                  final status = item.stringValue(['status'], fallback: 'published');
                  final createdAt = item.dateValue(['createdAt']);

                  return AdminRecordCard(
                    leadingIcon: Icons.star_border_rounded,
                    title: serviceTitle,
                    subtitle: comment,
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(
                        icon: Icons.star_rate_rounded,
                        label: '$rating / 5',
                      ),
                      AdminMetaPill(icon: Icons.person_outline, label: customer),
                      AdminMetaPill(icon: Icons.storefront_outlined, label: vendor),
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.date(createdAt),
                      ),
                    ],
                    actions: [
                      OutlinedButton.icon(
                        onPressed: () => _updateReviewStatus(item.id, 'hidden'),
                        icon: const Icon(Icons.visibility_off_outlined),
                        label: const Text('Hide'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _updateReviewStatus(item.id, 'published'),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Publish'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await AdminHelpers.confirm(
                            context,
                            title: 'Delete review?',
                            message: 'This will permanently delete this review.',
                            confirmText: 'Delete',
                          );
                          if (!confirmed) return;
                          try {
                            await widget.service.deleteDocument('reviews', item.id);
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'Review deleted');
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

  Future<void> _updateReviewStatus(String id, String status) async {
    try {
      await widget.service.updateDocument('reviews', id, {'status': status});
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Review marked as $status');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}
