import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
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
  String _selectedStatus = 'published';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AdminSearchBar(
                hintText: 'Search blogs by title, category, author, or status',
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showBlogEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Blog'),
            ),
          ],
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

              final allBlogs = (snapshot.data?.docs ?? [])
                  .map(AdminCollectionItem.fromDoc)
                  .toList();
              final publishedCount = allBlogs
                  .where((item) => _statusOf(item) == 'published')
                  .length;
              final draftCount = allBlogs.length - publishedCount;
              final blogs = allBlogs
                  .where((item) => _statusOf(item) == _selectedStatus)
                  .where(
                    (item) => AdminHelpers.matchesSearch(item.data, _search),
                  )
                  .toList();

              return Column(
                children: [
                  _BlogStatusTabs(
                    selectedStatus: _selectedStatus,
                    publishedCount: publishedCount,
                    draftCount: draftCount,
                    onChanged: (status) =>
                        setState(() => _selectedStatus = status),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: blogs.isEmpty
                        ? AdminEmptyState(
                            title: _selectedStatus == 'published'
                                ? 'No published blogs'
                                : 'No draft blogs',
                            message: _search.trim().isEmpty
                                ? 'Blogs in this publication state will appear here.'
                                : 'No blogs in this tab match your search.',
                            icon: _selectedStatus == 'published'
                                ? Icons.public_outlined
                                : Icons.edit_note_outlined,
                          )
                        : ListView.separated(
                            itemCount: blogs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
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
                                  AdminMetaPill(
                                    icon: Icons.person_outline,
                                    label: author,
                                  ),
                                  AdminMetaPill(
                                    icon: Icons.calendar_today_outlined,
                                    label: AdminFormatters.date(createdAt),
                                  ),
                                ],
                                actions: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showBlogEditor(item: item),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                  ),
                                  if (_statusOf(item) == 'draft')
                                    FilledButton.icon(
                                      onPressed: () =>
                                          _changeStatus(item.id, 'published'),
                                      icon: const Icon(Icons.publish_outlined),
                                      label: const Text('Publish'),
                                    )
                                  else
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _changeStatus(item.id, 'draft'),
                                      icon: const Icon(
                                        Icons.edit_note_outlined,
                                      ),
                                      label: const Text('Move to Draft'),
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
                                        AdminHelpers.showSnack(
                                          context,
                                          'Blog deleted',
                                        );
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
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _statusOf(AdminCollectionItem item) =>
      item.stringValue(['status'], fallback: 'draft').toLowerCase() ==
          'published'
      ? 'published'
      : 'draft';

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

  Future<void> _showBlogEditor({AdminCollectionItem? item}) async {
    final result = await showModalBottomSheet<_BlogEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlogEditorSheet(item: item),
    );
    if (!mounted || result == null) return;
    try {
      final values = Map<String, dynamic>.from(result.values);
      if (result.image != null) {
        values['imageUrl'] = await StorageService().uploadBlogImage(
          image: result.image!,
        );
      }
      if (item == null) {
        await widget.service.createBlog(values);
      } else {
        await widget.service.updateBlog(item.id, values);
      }
      if (!mounted) return;
      AdminHelpers.showSnack(
        context,
        item == null ? 'Blog created' : 'Blog updated',
      );
    } catch (error) {
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}

class _BlogStatusTabs extends StatelessWidget {
  const _BlogStatusTabs({
    required this.selectedStatus,
    required this.publishedCount,
    required this.draftCount,
    required this.onChanged,
  });

  final String selectedStatus;
  final int publishedCount;
  final int draftCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AdminAppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminAppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BlogStatusTab(
              label: 'Published',
              count: publishedCount,
              selected: selectedStatus == 'published',
              onTap: () => onChanged('published'),
            ),
            const SizedBox(width: 4),
            _BlogStatusTab(
              label: 'Drafts',
              count: draftCount,
              selected: selectedStatus == 'draft',
              onTap: () => onChanged('draft'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogStatusTab extends StatelessWidget {
  const _BlogStatusTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AdminAppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? Colors.white : AdminAppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BlogEditorResult {
  const _BlogEditorResult({required this.values, this.image});

  final Map<String, dynamic> values;
  final XFile? image;
}

class _BlogEditorSheet extends StatefulWidget {
  final AdminCollectionItem? item;

  const _BlogEditorSheet({this.item});

  @override
  State<_BlogEditorSheet> createState() => _BlogEditorSheetState();
}

class _BlogEditorSheetState extends State<_BlogEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _author;
  late final TextEditingController _content;
  late final String _existingImageUrl;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  late String _status;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(
      text: item?.stringValue(['title', 'heading'], fallback: '') ?? '',
    );
    _category = TextEditingController(
      text: item?.stringValue(['category'], fallback: 'Planning') ?? 'Planning',
    );
    _author = TextEditingController(
      text:
          item?.stringValue(['authorName', 'author'], fallback: 'Admin') ??
          'Admin',
    );
    _existingImageUrl = item?.stringValue(['imageUrl'], fallback: '') ?? '';
    _content = TextEditingController(
      text: item?.stringValue(['content', 'description'], fallback: '') ?? '',
    );
    _status =
        item?.stringValue(['status'], fallback: 'draft').toLowerCase() ??
        'draft';
    if (_status != 'published') _status = 'draft';
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _author.dispose();
    _content.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _BlogEditorResult(
        values: <String, dynamic>{
          'title': _title.text.trim(),
          'category': _category.text.trim(),
          'authorName': _author.text.trim(),
          'imageUrl': _existingImageUrl,
          'content': _content.text.trim(),
          'status': _status,
        },
        image: _selectedImage,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select that image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.item == null ? 'Write a new blog' : 'Edit blog',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Published articles appear on the customer dashboard.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              _BlogField(controller: _title, label: 'Title', required: true),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BlogField(
                      controller: _category,
                      label: 'Category',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BlogField(
                      controller: _author,
                      label: 'Author',
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Cover image',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _BlogImagePicker(
                imageBytes: _selectedImageBytes,
                existingImageUrl: _existingImageUrl,
                onTap: _pickImage,
              ),
              const SizedBox(height: 14),
              _BlogField(
                controller: _content,
                label: 'Full article content',
                required: true,
                maxLines: 10,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Publication status',
                ),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'draft'),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    widget.item == null ? 'Create Blog' : 'Save Changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlogImagePicker extends StatelessWidget {
  const _BlogImagePicker({
    required this.imageBytes,
    required this.existingImageUrl,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final String existingImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || existingImageUrl.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 165,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AdminAppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminAppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes!, fit: BoxFit.cover)
            else if (existingImageUrl.trim().isNotEmpty)
              Image.network(
                existingImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Container(
              color: hasImage ? Colors.black.withAlpha(65) : Colors.transparent,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasImage ? Icons.edit_rounded : Icons.add_photo_alternate,
                    color: hasImage ? Colors.white : AdminAppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    hasImage ? 'Change cover image' : 'Choose cover image',
                    style: TextStyle(
                      color: hasImage
                          ? Colors.white
                          : AdminAppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!hasImage) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Select an image from this device',
                      style: TextStyle(
                        color: AdminAppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final int maxLines;

  const _BlogField({
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
          : null,
      decoration: InputDecoration(labelText: label),
    );
  }
}
