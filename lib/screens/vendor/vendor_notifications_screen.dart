import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/notification_card.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  String? _markingNotificationId;
  bool _isMarkingAllRead = false;

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

  Future<void> _markAllAsRead(String vendorId) async {
    if (_isMarkingAllRead) return;

    setState(() => _isMarkingAllRead = true);
    try {
      await _notificationService.markAllAsRead(vendorId);
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
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: currentUser == null
          ? const _MessageState(
              icon: Icons.login_outlined,
              title: 'Please login again.',
              message: 'Your vendor session is no longer available.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationService.getNotifications(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final message = error is FirebaseException
                      ? error.message ?? error.code
                      : error.toString();
                  return _MessageState(
                    icon: Icons.error_outline,
                    title: 'Could not load notifications',
                    message: message,
                  );
                }

                final notifications = (snapshot.data?.docs ?? [])
                    .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
                    .toList();
                if (notifications.isEmpty) {
                  return const _MessageState(
                    icon: Icons.notifications_none_outlined,
                    title: 'You have no notifications yet.',
                    message: 'Booking and inquiry updates will appear here.',
                  );
                }

                final grouped = _GroupedNotifications.from(notifications);
                final hasUnread = notifications.any((item) => !item.isRead);

                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: TextButton(
                          onPressed: hasUnread && !_isMarkingAllRead
                              ? () => _markAllAsRead(currentUser.uid)
                              : null,
                          child: Text(
                            _isMarkingAllRead
                                ? 'Marking...'
                                : 'Mark all as read',
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: [
                          if (grouped.today.isNotEmpty)
                            ..._section('TODAY', grouped.today),
                          if (grouped.yesterday.isNotEmpty)
                            ..._section('YESTERDAY', grouped.yesterday),
                          if (grouped.earlier.isNotEmpty)
                            ..._section('EARLIER', grouped.earlier),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  List<Widget> _section(String title, List<NotificationModel> notifications) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
      ),
      ...notifications.map(
        (notification) => NotificationCard(
          notification: notification,
          isLoading: _markingNotificationId == notification.id,
          onTap: notification.isRead ? null : () => _markAsRead(notification),
        ),
      ),
    ];
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
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
    final todayBoundary = DateTime(now.year, now.month, now.day);
    final yesterdayBoundary = todayBoundary.subtract(const Duration(days: 1));
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final earlier = <NotificationModel>[];

    for (final notification in notifications) {
      final date = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );
      if (date == todayBoundary) {
        today.add(notification);
      } else if (date == yesterdayBoundary) {
        yesterday.add(notification);
      } else {
        earlier.add(notification);
      }
    }

    return _GroupedNotifications(
      today: today,
      yesterday: yesterday,
      earlier: earlier,
    );
  }
}
