import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

class AdminBlogsScreen extends StatefulWidget {
  const AdminBlogsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

class _AdminBlogsScreenState extends State<AdminBlogsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search blogs by title, category, author, or status',
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: widget.service.collectionStream('blogs'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AdminEmptyState(
                  title: 'Unable to load blogs',
                  message: snapshot.error.toString(),
                  icon: Icons.error_outline,
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final blogs = docs
                  .map((doc) => AdminCollectionItem.fromDoc(doc))
                  .where(
                    (item) => AdminHelpers.matchesSearch(item.data, _search),
                  )
                  .toList();

              if (blogs.isEmpty) {
                return const AdminEmptyState(
                  title: 'No blogs found',
                  message: 'Blog posts and planning tips will appear here.',
                  icon: Icons.article_outlined,
                );
              }

              return ListView.separated(
                itemCount: blogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = blogs[index];
                  final title = item.stringValue([
                    'title',
                    'heading',
                  ], fallback: 'Untitled blog');
                  final excerpt = item.stringValue([
                    'excerpt',
                    'description',
                    'content',
                  ], fallback: 'No description');
                  final category = item.stringValue([
                    'category',
                  ], fallback: 'Planning');
                  final author = item.stringValue([
                    'author',
                    'authorName',
                  ], fallback: 'Admin');
                  final status = item.stringValue([
                    'status',
                  ], fallback: 'draft');
                  final createdAt = item.dateValue([
                    'createdAt',
                    'publishedAt',
                  ]);

                  return AdminRecordCard(
                    leadingIcon: Icons.article_outlined,
                    title: title,
                    subtitle: excerpt,
                    trailing: AdminStatusChip(label: status),
                    meta: [
                      AdminMetaPill(
                        icon: Icons.category_outlined,
                        label: category,
                      ),
                      AdminMetaPill(icon: Icons.person_outline, label: author),
                      AdminMetaPill(
                        icon: Icons.calendar_today_outlined,
                        label: AdminFormatters.date(createdAt),
                      ),
                    ],
                    actions: [
                      FilledButton.icon(
                        onPressed: () => _changeStatus(item.id, 'published'),
                        icon: const Icon(Icons.publish_outlined),
                        label: const Text('Publish'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _changeStatus(item.id, 'draft'),
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('Draft'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await AdminHelpers.confirm(
                            context,
                            title: 'Delete blog?',
                            message:
                                'This will permanently delete this blog post.',
                            confirmText: 'Delete',
                          );
                          if (!confirmed) return;
                          try {
                            await widget.service.deleteDocument(
                              'blogs',
                              item.id,
                            );
                            if (!mounted) return;
                            AdminHelpers.showSnack(context, 'Blog deleted');
                          } catch (error) {
                            if (!mounted) return;
                            AdminHelpers.showSnack(
                              context,
                              error.toString(),
                              isError: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _changeStatus(String id, String status) async {
    try {
      await widget.service.updateBlogStatus(id, status);
      if (!mounted) return;
      AdminHelpers.showSnack(context, 'Blog moved to $status');
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}
