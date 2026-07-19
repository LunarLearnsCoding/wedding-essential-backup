import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/blog_model.dart';

class BlogDetailsScreen extends StatelessWidget {
  final BlogModel blog;

  const BlogDetailsScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wedding Journal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blog.imageUrl.trim().isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    blog.imageUrl.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _BlogImagePlaceholder(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.selectedSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        blog.category,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      blog.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 27,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${blog.authorName.isEmpty ? 'Admin' : blog.authorName} • ${DateFormat('dd MMM yyyy').format(blog.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 18),
                    Text(
                      blog.content,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlogImagePlaceholder extends StatelessWidget {
  const _BlogImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.selectedSurface,
      child: const Icon(
        Icons.article_outlined,
        color: AppColors.primary,
        size: 54,
      ),
    );
  }
}
