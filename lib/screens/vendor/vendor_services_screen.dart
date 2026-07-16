import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import 'vendor_service_form_screen.dart';

class VendorServicesScreen extends StatefulWidget {
  const VendorServicesScreen({super.key});

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  bool _didRunDiagnostics = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || _didRunDiagnostics) return;

      _didRunDiagnostics = true;
      debugVendorServices(currentUser.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final serviceService = ServiceService();

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendorServiceFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: serviceService.getServicesByVendor(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return const Center(child: Text('No services added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];

              return _ServiceCard(
                service: service,
                onUpdate: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VendorServiceFormScreen(service: service),
                    ),
                  );
                },
                onToggleStatus: () async {
                  await serviceService.updateServiceStatus(
                    service.id,
                    !service.isActive,
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Service'),
                        content: const Text(
                          'Are you sure you want to delete this service?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await serviceService.deleteService(service.id);
                  }
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 1),
    );
  }
}

Future<void> debugVendorServices(String vendorId) async {
  try {
    final allSnapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.services)
        .get();

    debugPrint('CURRENT VENDOR UID: "$vendorId"');
    debugPrint('FIREBASE PROJECT ID: ${Firebase.app().options.projectId}');
    debugPrint('SERVICES COLLECTION: ${FirestoreCollections.services}');
    debugPrint('ALL SERVICE COUNT: ${allSnapshot.docs.length}');

    for (final doc in allSnapshot.docs) {
      final value = doc.data()['vendorId'];
      debugPrint(
        'SERVICE ${doc.id}: vendorId="$value", type=${value.runtimeType}',
      );
    }

    final filteredSnapshot = await FirebaseFirestore.instance
        .collection(FirestoreCollections.services)
        .where('vendorId', isEqualTo: vendorId)
        .get();

    debugPrint('FILTERED SERVICE COUNT: ${filteredSnapshot.docs.length}');
  } on FirebaseException catch (error) {
    debugPrint(
      'SERVICE DIAGNOSTIC FIREBASE ERROR: '
      'code=${error.code}, message=${error.message}',
    );
    rethrow;
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onUpdate;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onUpdate,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = service.isActive ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceImageHeader(
            imageUrl: service.imageUrls.isEmpty
                ? ''
                : service.imageUrls.first.trim(),
            statusLabel: service.isActive ? 'Active' : 'Inactive',
            statusColor: statusColor,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _CategoryPill(text: service.category),
                    _LocationPill(text: service.location),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  service.description.trim().isEmpty
                      ? 'No description added.'
                      : service.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 420;

                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: isNarrow
                          ? WrapAlignment.start
                          : WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: onUpdate,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Update'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onToggleStatus,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(service.isActive ? 'Hide' : 'Activate'),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          tooltip: 'Delete service',
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.red,
                            backgroundColor: Colors.red.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 20),
                        ),
                      ],
                    );

                    final price = Text(
                      'Rs. ${service.price.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [price, const SizedBox(height: 10), actions],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: price),
                        const SizedBox(width: 12),
                        Flexible(child: actions),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceImageHeader extends StatelessWidget {
  final String imageUrl;
  final String statusLabel;
  final Color statusColor;

  const _ServiceImageHeader({
    required this.imageUrl,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 150,
            child: hasImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _ServiceImagePlaceholder();
                    },
                  )
                : const _ServiceImagePlaceholder(),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _StatusChip(label: statusLabel, color: statusColor),
          ),
        ],
      ),
    );
  }
}

class _ServiceImagePlaceholder extends StatelessWidget {
  const _ServiceImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      color: AppColors.selectedSurface.withValues(alpha: 0.6),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 34),
          SizedBox(height: 8),
          Text(
            'No service image',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String text;

  const _CategoryPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final label = text.trim().isEmpty ? 'Uncategorized' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.selectedSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  final String text;

  const _LocationPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final label = text.trim().isEmpty ? 'Location not set' : text.trim();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: AppColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
