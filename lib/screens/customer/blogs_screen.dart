import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/blog_model.dart';
import '../../services/blog_service.dart';
import 'widgets/blog_summary_card.dart';

/// Displays the blogs page and coordinates the actions available on it.
class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _BlogsScreenState extends State<BlogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _JournalHeader(onBack: () => Navigator.maybePop(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search wedding articles...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<BlogModel>>(
                stream: BlogService().getPublishedBlogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _BlogState(
                      icon: Icons.error_outline,
                      title: 'Could not load articles',
                      message: snapshot.error.toString(),
                    );
                  }

                  final query = _searchController.text.trim().toLowerCase();
                  final blogs = (snapshot.data ?? const <BlogModel>[])
                      .where(
                        (blog) =>
                            query.isEmpty ||
                            blog.title.toLowerCase().contains(query) ||
                            blog.category.toLowerCase().contains(query) ||
                            blog.authorName.toLowerCase().contains(query) ||
                            blog.content.toLowerCase().contains(query),
                      )
                      .toList();
                  if (blogs.isEmpty) {
                    return _BlogState(
                      icon: Icons.menu_book_outlined,
                      title: query.isEmpty
                          ? 'No published articles yet'
                          : 'No articles found',
                      message: query.isEmpty
                          ? 'Wedding advice and inspiration will appear here.'
                          : 'Try a different title, category, or keyword.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
                    itemCount: blogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        BlogSummaryCard(blog: blogs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the reusable journal header UI component.
class _JournalHeader extends StatelessWidget {
  const _JournalHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Wedding Tips & Blogs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.auto_stories_outlined, color: Colors.white),
        ],
      ),
    );
  }
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _BlogState extends StatelessWidget {
  const _BlogState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
