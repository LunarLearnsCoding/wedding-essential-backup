import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/notification_card.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'browse_services_screen.dart';
import 'customer_dashboard_screen.dart';
import 'customer_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isMarkingAllRead = false;
  String? _markingNotificationId;

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead || _markingNotificationId == notification.id) {
      return;
    }

    setState(() {
      _markingNotificationId = notification.id;
    });

    try {
      await _notificationService.markAsRead(notification.id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark notification as read: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingNotificationId = null;
        });
      }
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    if (_isMarkingAllRead) return;

    setState(() {
      _isMarkingAllRead = true;
    });

    try {
      await _notificationService.markAllAsRead(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllRead = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please login again.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _notificationService.getNotifications(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              final message = error is FirebaseException
                  ? 'Failed to load notifications: ${error.message ?? error.code}'
                  : 'Failed to load notifications: $error';

              return _NotificationScaffoldBody(
                onMarkAllRead: null,
                child: _MessageState(
                  icon: Icons.error_outline,
                  title: 'Could not load notifications',
                  message: message,
                ),
              );
            }

            final notifications =
                (snapshot.data?.docs ?? [])
                    .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (notifications.isEmpty) {
              return _NotificationScaffoldBody(
                onMarkAllRead: null,
                child: const _MessageState(
                  icon: Icons.notifications_none_outlined,
                  title: 'You have no notifications yet.',
                  message:
                      'Updates about bookings and inquiries will appear here.',
                ),
              );
            }

            final grouped = _GroupedNotifications.from(notifications);
            final hasUnread = notifications.any(
              (notification) => !notification.isRead,
            );

            return _NotificationScaffoldBody(
              onMarkAllRead: hasUnread && !_isMarkingAllRead
                  ? () => _markAllAsRead(currentUser.uid)
                  : null,
              isMarkingAllRead: _isMarkingAllRead,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (grouped.today.isNotEmpty) ...[
                    const _SectionHeader('TODAY'),
                    const SizedBox(height: 12),
                    ...grouped.today.map(_notificationCard),
                    const SizedBox(height: 18),
                  ],
                  if (grouped.yesterday.isNotEmpty) ...[
                    const _SectionHeader('YESTERDAY'),
                    const SizedBox(height: 12),
                    ...grouped.yesterday.map(_notificationCard),
                    const SizedBox(height: 18),
                  ],
                  if (grouped.earlier.isNotEmpty) ...[
                    const _SectionHeader('EARLIER'),
                    const SizedBox(height: 12),
                    ...grouped.earlier.map(_notificationCard),
                  ],
                ],
              ),
            );
          },
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
                  builder: (_) => const CustomerDashboardScreen(),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BrowseServicesScreen()),
              );
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerProfileScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _notificationCard(NotificationModel notification) {
    return NotificationCard(
      notification: notification,
      isLoading: _markingNotificationId == notification.id,
      onTap: () => _markAsRead(notification),
    );
  }
}

class _NotificationScaffoldBody extends StatelessWidget {
  final Widget child;
  final VoidCallback? onMarkAllRead;
  final bool isMarkingAllRead;

  const _NotificationScaffoldBody({
    required this.child,
    required this.onMarkAllRead,
    this.isMarkingAllRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onMarkAllRead,
                child: Text(
                  isMarkingAllRead ? 'Marking...' : 'Mark all read',
                  style: TextStyle(
                    color: onMarkAllRead == null
                        ? AppColors.textSecondary
                        : AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 38),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
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

class _GroupedNotifications {
  final List<NotificationModel> today;
  final List<NotificationModel> yesterday;
  final List<NotificationModel> earlier;

  const _GroupedNotifications({
    required this.today,
    required this.yesterday,
    required this.earlier,
  });

  factory _GroupedNotifications.from(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

    for (final notification in notifications) {
      final createdDay = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (createdDay == today) {
        todayItems.add(notification);
      } else if (createdDay == yesterday) {
        yesterdayItems.add(notification);
      } else {
        earlierItems.add(notification);
      }
    }

    return _GroupedNotifications(
      today: todayItems,
      yesterday: yesterdayItems,
      earlier: earlierItems,
    );
  }
}
