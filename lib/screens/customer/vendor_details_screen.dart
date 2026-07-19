import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../models/review_model.dart';
import '../../models/service_model.dart';
import '../../models/vendor_model.dart';
import '../../services/review_service.dart';
import '../../services/service_service.dart';
import 'service_details_screen.dart';

class VendorDetailsScreen extends StatelessWidget {
  final String vendorId;
  static final ReviewService _reviewService = ReviewService();

  const VendorDetailsScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vendor Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirestoreCollections.vendors)
            .doc(vendorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              title: 'Could not load vendor',
              message: snapshot.error.toString(),
            );
          }
          final data = snapshot.data?.data();
          if (data == null) {
            return const _MessageState(
              title: 'Vendor not found',
              message: 'This vendor profile is no longer available.',
            );
          }

          final vendor = VendorModel.fromMap(vendorId, data);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              StreamBuilder<List<ReviewModel>>(
                stream: _reviewService.getReviewsByVendor(vendorId),
                builder: (context, reviewSnapshot) {
                  final reviews = reviewSnapshot.data ?? const <ReviewModel>[];
                  return _VendorProfileCard(vendor: vendor, reviews: reviews);
                },
              ),
              const SizedBox(height: 26),
              const _SectionTitle('Services by this vendor'),
              const SizedBox(height: 12),
              _VendorServices(vendorId: vendorId),
              const SizedBox(height: 26),
              const _SectionTitle('Customer Reviews'),
              const SizedBox(height: 12),
              _VendorReviews(vendorId: vendorId),
            ],
          );
        },
      ),
    );
  }
}

class _VendorProfileCard extends StatelessWidget {
  final VendorModel vendor;
  final List<ReviewModel> reviews;

  const _VendorProfileCard({required this.vendor, required this.reviews});

  Future<void> _contact(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact information is unavailable.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = vendor.businessName.trim().isNotEmpty
        ? vendor.businessName.trim()
        : vendor.name.trim();
    final averageRating = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (sum, review) => sum + review.rating) /
              reviews.length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.selectedSurface,
                  child: Text(
                    displayName.isEmpty ? 'V' : displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isEmpty ? 'Vendor' : displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(vendor.name),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.selectedSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          vendor.category.trim().isEmpty
                              ? 'Wedding service provider'
                              : vendor.category.trim(),
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                Text(
                  '${averageRating.toStringAsFixed(1)} (${reviews.length} reviews)',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (vendor.bio.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              const Divider(color: AppColors.border),
              const SizedBox(height: 14),
              const Text(
                'About the business',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              Text(
                vendor.bio.trim(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 15),
            _InfoLine(
              icon: Icons.location_on_outlined,
              value: vendor.locations.isEmpty
                  ? 'Location not provided'
                  : vendor.locations.join(', '),
            ),
            _InfoLine(
              icon: Icons.email_outlined,
              value: vendor.email.trim().isEmpty
                  ? 'Email not provided'
                  : vendor.email.trim(),
            ),
            _InfoLine(
              icon: Icons.phone_outlined,
              value: vendor.phone.trim().isEmpty
                  ? 'Phone not provided'
                  : vendor.phone.trim(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vendor.phone.trim().isEmpty
                        ? null
                        : () => _contact(
                            context,
                            Uri(scheme: 'tel', path: vendor.phone.trim()),
                          ),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vendor.email.trim().isEmpty
                        ? null
                        : () => _contact(
                            context,
                            Uri(scheme: 'mailto', path: vendor.email.trim()),
                          ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email'),
                  ),
                ),
              ],
            ),
            _VendorSocialLinks(vendor: vendor),
          ],
        ),
      ),
    );
  }
}

class _VendorSocialLinks extends StatelessWidget {
  final VendorModel vendor;

  const _VendorSocialLinks({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final links = <(String, dynamic, String)>[
      (vendor.facebookUrl.trim(), FontAwesomeIcons.facebookF, 'Facebook'),
      (vendor.instagramUrl.trim(), FontAwesomeIcons.instagram, 'Instagram'),
      (vendor.tiktokUrl.trim(), FontAwesomeIcons.tiktok, 'TikTok'),
      (vendor.websiteUrl.trim(), FontAwesomeIcons.globe, 'Website'),
    ].where((item) => item.$1.isNotEmpty).toList();
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect online',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: links
                .map(
                  (item) => OutlinedButton.icon(
                    onPressed: () => _openSocialLink(context, item.$1),
                    icon: FaIcon(item.$2, size: 19),
                    label: Text(item.$3),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

Future<void> _openSocialLink(BuildContext context, String value) async {
  var normalized = value.trim();
  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = 'https://$normalized';
  }
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    _showSocialLinkError(context);
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) _showSocialLinkError(context);
}

void _showSocialLinkError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not open this social media link.')),
  );
}

class _VendorServices extends StatelessWidget {
  final String vendorId;
  static final ServiceService _serviceService = ServiceService();

  const _VendorServices({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceModel>>(
      stream: _serviceService.getServicesByVendor(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Failed to load services: ${snapshot.error}');
        }
        final services =
            (snapshot.data ?? []).where((service) => service.isActive).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (services.isEmpty) {
          return const _EmptyCard('This vendor has no active services.');
        }
        return Column(
          children: services.map((service) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: _ServiceImage(service: service),
                title: Text(service.name),
                subtitle: Text(
                  '${service.category} • ${service.location}\nRs. ${service.price.toStringAsFixed(0)}',
                ),
                isThreeLine: true,
                trailing: const Text('View Details'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailsScreen(serviceId: service.id),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _VendorReviews extends StatelessWidget {
  final String vendorId;
  static final ReviewService _reviewService = ReviewService();

  const _VendorReviews({required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getReviewsForVendor(vendorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Failed to load reviews: ${snapshot.error}');
        }
        final reviews = snapshot.data ?? []
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (reviews.isEmpty) {
          return const _EmptyCard('This vendor has no reviews yet.');
        }
        return Column(
          children: reviews.map((review) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.customerName.trim().isEmpty
                                ? 'Customer'
                                : review.customerName.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(review.createdAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.serviceName.trim().isEmpty
                          ? 'Service'
                          : review.serviceName.trim(),
                      style: const TextStyle(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 8),
                    Text(review.reviewText),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ServiceImage extends StatelessWidget {
  final ServiceModel service;

  const _ServiceImage({required this.service});

  @override
  Widget build(BuildContext context) {
    if (service.imageUrls.isEmpty) {
      return const Icon(Icons.image_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        service.imageUrls.first,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoLine({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard(this.message);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: Text(message)),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;

  const _MessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
