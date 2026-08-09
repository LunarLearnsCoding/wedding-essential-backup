import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'firebase_storage_image.dart';

/// Renders the reusable profile avatar UI component.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.userId,
    required this.fallbackName,
    this.imageUrl,
    this.radius = 24,
    this.backgroundColor = AppColors.selectedSurface,
    this.foregroundColor = AppColors.primary,
  });

  final String userId;
  final String fallbackName;
  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final directUrl = imageUrl?.trim() ?? '';
    if (directUrl.isNotEmpty) return _avatar(directUrl);
    if (userId.trim().isEmpty) return _fallback();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('public_profiles')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final url =
            snapshot.data?.data()?['profileImageUrl']?.toString().trim() ?? '';
        return url.isEmpty ? _fallback() : _avatar(url);
      },
    );
  }

  Widget _avatar(String source) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: FirebaseStorageImage(
            source: source,
            errorBuilder: (_) => _fallbackContent(),
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: _fallbackContent(),
    );
  }

  Widget _fallbackContent() {
    final name = fallbackName.trim();
    return name.isEmpty
        ? Icon(Icons.person_outline, size: radius, color: foregroundColor)
        : Text(
            name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: foregroundColor,
              fontSize: radius * 0.8,
              fontWeight: FontWeight.w900,
            ),
          );
  }
}
