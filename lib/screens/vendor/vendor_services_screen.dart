import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/firebase_storage_image.dart';
import '../../core/widgets/app_information_sheet.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import 'vendor_service_form_screen.dart';

/// Displays the vendor services page and coordinates the actions available on it.
class VendorServicesScreen extends StatelessWidget {
  const VendorServicesScreen({super.key});

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
                  final confirm = await showAppConfirmationSheet(
                    context,
                    title: 'Delete service?',
                    message:
                        'This service will be permanently removed from your listings.',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );

                  if (confirm) {
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

/// Renders the reusable service card UI component.
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

                Text(
                  'Rs. ${service.price.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ServiceActionButton(
                        label: 'Update',
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryDark,
                        onPressed: onUpdate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ServiceActionButton(
                        label: service.isActive ? 'Hide' : 'Activate',
                        icon: service.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.primary,
                        onPressed: onToggleStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ServiceActionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the reusable service action button UI component.
class _ServiceActionButton extends StatelessWidget {
  const _ServiceActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.05),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        minimumSize: const Size(0, 42),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Renders the reusable service image header UI component.
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
                ? FirebaseStorageImage(
                    source: imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context) {
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

/// Renders the reusable service image placeholder UI component.
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

/// Renders the reusable status chip UI component.
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

/// Renders the reusable category pill UI component.
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

/// Renders the reusable location pill UI component.
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
