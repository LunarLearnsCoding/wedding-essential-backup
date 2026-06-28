import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/notification_card.dart';
import '../../models/notification_model.dart';
import 'browse_services_screen.dart';
import 'customer_dashboard_screen.dart';
import 'customer_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = [
      NotificationModel(
        id: 'notif_today_1',
        title: 'Booking Confirmed',
        message:
            'The Grand Pavilion has confirmed your booking for 15 January 2026.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.booking,
        isRead: false,
      ),
      NotificationModel(
        id: 'notif_today_2',
        title: 'New RSVP Response',
        message: 'John Doe has accepted your invitation.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.guest,
        isRead: false,
      ),
    ];

    final yesterday = [
      NotificationModel(
        id: 'notif_yesterday_1',
        title: 'Inquiry Replied',
        message:
            'Lumière Photography replied to your inquiry. View their message now.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.inquiry,
        isRead: true,
      ),
      NotificationModel(
        id: 'notif_yesterday_2',
        title: 'Task Due Soon',
        message:
            '"Book photographer & videographer" is due in 3 days.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.checklist,
        isRead: true,
      ),
    ];

    final earlier = [
      NotificationModel(
        id: 'notif_earlier_1',
        title: 'Payment Reminder',
        message:
            'Your remaining balance for Saveur Catering is due soon.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        type: NotificationType.payment,
        isRead: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Marked all as read',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            const _SectionHeader('TODAY'),

            const SizedBox(height: 12),

            ...today.map(
              (notification) =>
                  NotificationCard(notification: notification),
            ),

            const SizedBox(height: 18),

            const _SectionHeader('YESTERDAY'),

            const SizedBox(height: 12),

            ...yesterday.map(
              (notification) =>
                  NotificationCard(notification: notification),
            ),

            const SizedBox(height: 18),

            const _SectionHeader('EARLIER'),

            const SizedBox(height: 12),

            ...earlier.map(
              (notification) =>
                  NotificationCard(notification: notification),
            ),
          ],
        ),
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CustomerDashboardScreen(),
                ),
              );
              break;

            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const BrowseServicesScreen(),
                ),
              );
              break;

            case 2:
              break;

            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const CustomerProfileScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}