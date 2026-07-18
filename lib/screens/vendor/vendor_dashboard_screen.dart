import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/widgets/notification_card.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import '../../models/app_enums.dart';
import '../../models/booking_model.dart';
import '../../models/inquiry_model.dart';
import '../../models/notification_model.dart';
import '../../models/vendor_model.dart';
import '../../services/notification_service.dart';
import 'vendor_bookings_screen.dart';
import 'vendor_inquiries_screen.dart';
import 'vendor_notifications_screen.dart';
import 'vendor_reviews_screen.dart';
import 'vendor_service_form_screen.dart';
import 'vendor_services_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  Future<_DashboardData> _loadDashboardData(String vendorId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final results = await Future.wait([
        firestore.collection(FirestoreCollections.vendors).doc(vendorId).get(),
        firestore
            .collection(FirestoreCollections.services)
            .where('vendorId', isEqualTo: vendorId)
            .get(),
        firestore
            .collection(FirestoreCollections.bookings)
            .where('vendorId', isEqualTo: vendorId)
            .get(),
        firestore
            .collection(FirestoreCollections.inquiries)
            .where('vendorId', isEqualTo: vendorId)
            .get(),
        firestore
            .collection(FirestoreCollections.reviews)
            .where('vendorId', isEqualTo: vendorId)
            .get(),
      ]);

      final vendorDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final servicesSnapshot =
          results[1] as QuerySnapshot<Map<String, dynamic>>;
      final bookingsSnapshot =
          results[2] as QuerySnapshot<Map<String, dynamic>>;
      final inquiriesSnapshot =
          results[3] as QuerySnapshot<Map<String, dynamic>>;
      final reviewsSnapshot = results[4] as QuerySnapshot<Map<String, dynamic>>;

      final vendorData = vendorDoc.data();
      final vendor = vendorData == null
          ? null
          : VendorModel.fromMap(vendorDoc.id, vendorData);
      final bookings = bookingsSnapshot.docs
          .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
          .toList();
      final inquiries = inquiriesSnapshot.docs
          .map((doc) => InquiryModel.fromMap(doc.id, doc.data()))
          .toList();
      return _DashboardData(
        businessName: _vendorDisplayName(vendor),
        totalServices: servicesSnapshot.docs.length,
        pendingBookings: bookings
            .where((booking) => booking.status == BookingStatus.pending)
            .length,
        pendingInquiries: inquiries
            .where((inquiry) => inquiry.status == InquiryStatus.pending)
            .length,
        totalReviews: reviewsSnapshot.docs.length,
      );
    } catch (error, stackTrace) {
      debugPrint('Vendor dashboard load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please login again.')),
        bottomNavigationBar: VendorBottomNav(currentIndex: 0),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_DashboardData>(
        future: _loadDashboardData(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Column(
              children: [
                _DashboardHeader(businessName: 'Vendor'),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }

          if (snapshot.hasError) {
            return Column(
              children: [
                const _DashboardHeader(businessName: 'Vendor'),
                Expanded(
                  child: _DashboardMessageCard(
                    icon: Icons.error_outline,
                    title: 'Failed to load dashboard',
                    message: snapshot.error.toString(),
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data ?? const _DashboardData.empty();

          return Column(
            children: [
              _DashboardHeader(businessName: data.businessName),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatsGrid(data: data),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _open(context, const VendorServiceFormScreen()),
                          icon: const Icon(Icons.add_business_outlined),
                          label: const Text('Add Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _RecentNotifications(vendorId: currentUser.uid),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 0),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String businessName;

  const _DashboardHeader({required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            businessName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _DashboardData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _StatCard(
              title: 'Total Services',
              value: data.totalServices.toString(),
              icon: Icons.room_service_outlined,
              onTap: () => _open(context, const VendorServicesScreen()),
            ),
            _StatCard(
              title: 'Pending Bookings',
              value: data.pendingBookings.toString(),
              icon: Icons.calendar_month_outlined,
              onTap: () => _open(context, const VendorBookingsScreen()),
            ),
            _StatCard(
              title: 'Pending Inquiries',
              value: data.pendingInquiries.toString(),
              icon: Icons.message_outlined,
              onTap: () => _open(context, const VendorInquiriesScreen()),
            ),
            _StatCard(
              title: 'Reviews',
              value: data.totalReviews.toString(),
              icon: Icons.star_outline,
              onTap: () => _open(context, const VendorReviewsScreen()),
            ),
          ].map((child) => SizedBox(width: itemWidth, child: child)).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RecentNotifications extends StatefulWidget {
  final String vendorId;

  const _RecentNotifications({required this.vendorId});

  @override
  State<_RecentNotifications> createState() => _RecentNotificationsState();
}

class _RecentNotificationsState extends State<_RecentNotifications> {
  final NotificationService _notificationService = NotificationService();
  String? _markingNotificationId;

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead || _markingNotificationId == notification.id) {
      return;
    }

    setState(() => _markingNotificationId = notification.id);
    try {
      await _notificationService.markAsRead(notification.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read: $error')),
      );
    } finally {
      if (mounted) setState(() => _markingNotificationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle(title: 'Recent Notifications')),
            TextButton(
              onPressed: () =>
                  _open(context, const VendorNotificationsScreen()),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _notificationService.getRecentNotifications(widget.vendorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return _DashboardMessageCard(
                icon: Icons.error_outline,
                title: 'Could not load notifications',
                message: snapshot.error.toString(),
              );
            }

            final notifications = (snapshot.data?.docs ?? [])
                .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
                .toList();
            if (notifications.isEmpty) {
              return const _DashboardMessageCard(
                icon: Icons.notifications_none_outlined,
                title: 'No notifications yet',
                message: 'New booking and inquiry updates will appear here.',
              );
            }

            return Column(
              children: notifications
                  .map(
                    (notification) => NotificationCard(
                      notification: notification,
                      isLoading: _markingNotificationId == notification.id,
                      onTap: notification.isRead
                          ? null
                          : () => _markAsRead(notification),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DashboardMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DashboardMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final String businessName;
  final int totalServices;
  final int pendingBookings;
  final int pendingInquiries;
  final int totalReviews;

  const _DashboardData({
    required this.businessName,
    required this.totalServices,
    required this.pendingBookings,
    required this.pendingInquiries,
    required this.totalReviews,
  });

  const _DashboardData.empty()
    : businessName = 'Vendor',
      totalServices = 0,
      pendingBookings = 0,
      pendingInquiries = 0,
      totalReviews = 0;
}

String _vendorDisplayName(VendorModel? vendor) {
  if (vendor == null) {
    return 'Vendor';
  }

  final businessName = vendor.businessName.trim();
  if (businessName.isNotEmpty) {
    return businessName;
  }

  final name = vendor.name.trim();
  if (name.isNotEmpty) {
    return name;
  }

  return 'Vendor';
}

void _open(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
