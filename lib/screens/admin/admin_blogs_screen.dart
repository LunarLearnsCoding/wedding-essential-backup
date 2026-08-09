import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/admin_app_colors.dart';
import '../../core/widgets/firebase_storage_image.dart';
import '../../core/widgets/removable_image_preview.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../services/storage_service.dart';
import 'widgets/admin_empty_state.dart';
import 'widgets/admin_formatters.dart';
import 'widgets/admin_helpers.dart';
import 'widgets/admin_record_card.dart';
import 'widgets/admin_search_bar.dart';
import 'widgets/admin_status_chip.dart';

/// Displays the admin blogs page and coordinates the actions available on it.
class AdminBlogsScreen extends StatefulWidget {
  const AdminBlogsScreen({super.key, required this.service});

  final AdminService service;

  @override
  State<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
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
                                        await widget.service.deleteBlog(
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

  /// Opens the blog editor interface for the user.
  Future<void> _showBlogEditor({AdminCollectionItem? item}) async {
    final result = await showModalBottomSheet<_BlogEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlogEditorSheet(item: item),
    );
    if (!mounted || result == null) return;
    String? uploadedImageUrl;
    var blogSaved = false;
    try {
      final values = Map<String, dynamic>.from(result.values);
      final existingImageUrl =
          item?.stringValue(['imageUrl'], fallback: '') ?? '';
      var imageUrl = result.removeExistingImage ? '' : existingImageUrl;
      if (result.selectedImage != null) {
        final admin = FirebaseAuth.instance.currentUser;
        if (admin == null) {
          throw StateError('Your admin session has expired.');
        }
        uploadedImageUrl = await StorageService().uploadBlogImage(
          adminId: admin.uid,
          image: result.selectedImage!,
        );
        imageUrl = uploadedImageUrl;
      }
      values['imageUrl'] = imageUrl;
      if (item == null) {
        await widget.service.createBlog(values);
      } else {
        await widget.service.updateBlog(item.id, values);
      }
      blogSaved = true;
      if (existingImageUrl.isNotEmpty && existingImageUrl != imageUrl) {
        try {
          await widget.service.deleteBlogImage(existingImageUrl);
        } catch (error) {
          debugPrint('Could not delete replaced blog image: $error');
        }
      }
      if (!mounted) return;
      AdminHelpers.showSnack(
        context,
        item == null ? 'Blog created' : 'Blog updated',
      );
    } catch (error) {
      if (!blogSaved && uploadedImageUrl != null) {
        await widget.service.deleteBlogImage(uploadedImageUrl);
      }
      if (!mounted) return;
      AdminHelpers.showSnack(context, error.toString(), isError: true);
    }
  }
}

/// Renders the reusable blog status tabs UI component.
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

/// Renders the reusable blog status tab UI component.
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

/// Groups the data and behavior required by the blog editor result component.
class _BlogEditorResult {
  const _BlogEditorResult({
    required this.values,
    required this.selectedImage,
    required this.removeExistingImage,
  });

  final Map<String, dynamic> values;
  final XFile? selectedImage;
  final bool removeExistingImage;
}

/// Renders the reusable blog editor sheet UI component.
class _BlogEditorSheet extends StatefulWidget {
  final AdminCollectionItem? item;

  const _BlogEditorSheet({this.item});

  @override
  State<_BlogEditorSheet> createState() => _BlogEditorSheetState();
}

/// Manages the mutable state, user actions, and UI composition for the related screen.
class _BlogEditorSheetState extends State<_BlogEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _author;
  late final TextEditingController _content;
  late final String _existingImageUrl;
  XFile? _selectedImage;
  bool _removeExistingImage = false;
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

  /// Validates and saves the current save values.
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _BlogEditorResult(
        selectedImage: _selectedImage,
        removeExistingImage: _removeExistingImage,
        values: <String, dynamic>{
          'title': _title.text.trim(),
          'category': _category.text.trim(),
          'authorName': _author.text.trim(),
          'content': _content.text.trim(),
          'status': _status,
        },
      ),
    );
  }

  /// Lets the user choose the required value and stores the selection.
  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 900,
      imageQuality: 55,
    );
    if (image == null || !mounted) return;
    setState(() {
      _selectedImage = image;
      _removeExistingImage = true;
    });
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
                'Blog image (optional)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _selectedImage == null &&
                            (_existingImageUrl.isEmpty || _removeExistingImage)
                        ? 'Choose image'
                        : 'Replace image',
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snapshot) => RemovableImagePreview(
                    width: double.infinity,
                    height: 180,
                    image: snapshot.hasData
                        ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                        : const Center(child: CircularProgressIndicator()),
                    onRemove: () => setState(() => _selectedImage = null),
                  ),
                ),
              ] else if (_existingImageUrl.isNotEmpty &&
                  !_removeExistingImage) ...[
                const SizedBox(height: 12),
                RemovableImagePreview(
                  width: double.infinity,
                  height: 180,
                  image: FirebaseStorageImage(
                    source: _existingImageUrl,
                    fit: BoxFit.cover,
                  ),
                  onRemove: () => setState(() => _removeExistingImage = true),
                ),
              ],
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

/// Renders the reusable blog field UI component.
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
