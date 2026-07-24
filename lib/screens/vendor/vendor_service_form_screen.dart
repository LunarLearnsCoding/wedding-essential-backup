import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/firebase_storage_image.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../services/storage_service.dart';

class VendorServiceFormScreen extends StatefulWidget {
  final ServiceModel? service;

  const VendorServiceFormScreen({super.key, this.service});

  @override
  State<VendorServiceFormScreen> createState() =>
      _VendorServiceFormScreenState();
}

class _VendorServiceFormScreenState extends State<VendorServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _serviceNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _status = 'Active';
  bool _isSaving = false;
  bool _isLoadingProfileDetails = true;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = StorageService();
  final List<XFile> _newImages = [];
  late List<String> _existingImageUrls;

  bool get _isUpdateMode => widget.service != null;

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List<String>.from(
      widget.service?.imageUrls ?? const [],
    );
    _categoryController.text = widget.service?.category.trim() ?? '';
    _locationController.text = widget.service?.location.trim() ?? '';
    _loadVendorProfileDetails();

    final service = widget.service;
    if (service == null) return;

    _serviceNameController.text = service.name;
    _priceController.text = service.price.toStringAsFixed(0);
    _descriptionController.text = service.description;
    _status = service.isActive ? 'Active' : 'Paused';
  }

  Future<void> _loadVendorProfileDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoadingProfileDetails = false);
      return;
    }
    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(currentUser.uid)
          .get();
      final data = vendorDoc.data() ?? {};
      final category = data['category']?.toString().trim() ?? '';
      final location = _profileLocation(data);
      if (!mounted) return;
      if (category.isNotEmpty) _categoryController.text = category;
      if (location.isNotEmpty) _locationController.text = location;
    } finally {
      if (mounted) setState(() => _isLoadingProfileDetails = false);
    }
  }

  String _profileLocation(Map<String, dynamic> data) {
    final locations = data['locations'];
    if (locations is Iterable) {
      return locations
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .join(', ');
    }
    return data['location']?.toString().trim() ?? '';
  }

  Future<void> _pickImages() async {
    final available = 6 - _existingImageUrls.length - _newImages.length;
    if (available <= 0) {
      _showImageLimitMessage();
      return;
    }
    final selected = await _imagePicker.pickMultiImage(
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 55,
    );
    if (!mounted || selected.isEmpty) return;
    setState(() => _newImages.addAll(selected.take(available)));
    if (selected.length > available) _showImageLimitMessage();
  }

  void _showImageLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You can add up to 6 images.')),
    );
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isUpdateMode
                ? 'Please sign in again to update this service.'
                : 'Please sign in again to add a service.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existingService = widget.service;
      final now = DateTime.now();
      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(currentUser.uid)
          .get();
      final vendorData = vendorDoc.data() ?? {};
      final vendorId = currentUser.uid;
      final businessName = vendorData['businessName']?.toString().trim() ?? '';
      final profileName = vendorData['name']?.toString().trim() ?? '';
      final vendorName = businessName.isNotEmpty
          ? businessName
          : profileName.isNotEmpty
          ? profileName
          : existingService?.vendorName.trim().isNotEmpty == true
          ? existingService!.vendorName.trim()
          : currentUser.email ?? 'Vendor';
      final profileCategory = vendorData['category']?.toString().trim() ?? '';
      final vendorCategory = profileCategory.isNotEmpty
          ? profileCategory
          : existingService?.category.trim() ?? '';
      final profileLocation = _profileLocation(vendorData);
      final vendorLocation = profileLocation.isNotEmpty
          ? profileLocation
          : existingService?.location.trim() ?? '';
      if (vendorCategory.isEmpty) {
        throw StateError(
          'Your vendor profile does not have a service category. Update your business information before adding a service.',
        );
      }
      if (vendorLocation.isEmpty) {
        throw StateError(
          'Your vendor profile does not have a location. Update your business information before adding a service.',
        );
      }

      final uploadedUrls = await Future.wait(
        _newImages.map(
          (image) => _storageService.uploadServiceImage(
            vendorId: vendorId,
            image: image,
          ),
        ),
      );
      final completeImageUrls = [..._existingImageUrls, ...uploadedUrls];

      final service = ServiceModel(
        id: existingService?.id ?? '',
        vendorId: vendorId,
        vendorName: vendorName,
        name: _serviceNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: vendorCategory,
        location: vendorLocation,
        price: _parsePrice(_priceController.text),
        imageUrls: completeImageUrls,
        averageRating: existingService?.averageRating ?? 0,
        totalReviews: existingService?.totalReviews ?? 0,
        isActive: _status == 'Active',
        isFeatured: existingService?.isFeatured ?? false,
        createdAt: existingService?.createdAt ?? now,
        updatedAt: _isUpdateMode ? now : null,
      );

      if (_isUpdateMode) {
        await ServiceService().updateService(service);
      } else {
        await ServiceService().addService(service);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isUpdateMode
                ? 'Service updated successfully.'
                : 'Service published successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save service: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double _parsePrice(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ServiceFormHeader(
            title: _isUpdateMode ? 'Update Service' : 'Add Service',
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormCard(
                      title: 'Service Details',
                      children: [
                        _TextInput(
                          label: 'Service Name',
                          hint: 'Royal Photography',
                          controller: _serviceNameController,
                        ),

                        const Text(
                          'Service Images',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _pickImages,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                            ),
                            label: const Text('Select images'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        if (_existingImageUrls.isNotEmpty ||
                            _newImages.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 110,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ..._existingImageUrls.asMap().entries.map(
                                  (entry) => _ImagePreview(
                                    image: FirebaseStorageImage(
                                      source: entry.value,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_) => const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                                    onRemove: _isSaving
                                        ? null
                                        : () => setState(
                                            () => _existingImageUrls.removeAt(
                                              entry.key,
                                            ),
                                          ),
                                  ),
                                ),
                                ..._newImages.asMap().entries.map(
                                  (entry) => FutureBuilder<Uint8List>(
                                    future: entry.value.readAsBytes(),
                                    builder: (context, snapshot) => _ImagePreview(
                                      image: snapshot.hasData
                                          ? Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                      onRemove: _isSaving
                                          ? null
                                          : () => setState(
                                              () => _newImages.removeAt(
                                                entry.key,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _categoryController,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          decoration: _inputDecoration('Category').copyWith(
                            helperText:
                                'Taken from your vendor registration information.',
                            prefixIcon: const Icon(Icons.category_outlined),
                            suffixIcon: _isLoadingProfileDetails
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.lock_outline, size: 19),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _locationController,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          decoration: _inputDecoration('Location').copyWith(
                            helperText:
                                'Taken from your vendor registration information.',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: _isLoadingProfileDetails
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.lock_outline, size: 19),
                          ),
                        ),
                        const SizedBox(height: 14),

                        _TextInput(
                          label: 'Base Price',
                          hint: 'Rs. 50,000',
                          controller: _priceController,
                        ),

                        _TextInput(
                          label: 'Description',
                          hint: 'Describe your service clearly...',
                          controller: _descriptionController,
                          maxLines: 4,
                        ),

                        const SizedBox(height: 4),

                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: _inputDecoration('Listing Status'),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Paused',
                              child: Text('Paused'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _status = value ?? 'Active';
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveService,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isSaving
                              ? (_isUpdateMode ? 'Saving...' : 'Publishing...')
                              : (_isUpdateMode
                                    ? 'Save Changes'
                                    : 'Add Service'),
                        ),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Widget image;
  final VoidCallback? onRemove;
  const _ImagePreview({required this.image, required this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 104, height: 104, child: image),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceFormHeader extends StatelessWidget {
  final String title;

  const _ServiceFormHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 52, 22, 22),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vendor Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final bool requiredField;

  const _TextInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
  }) : requiredField = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: label.toLowerCase().contains('price')
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: label.toLowerCase().contains('price')
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                if (label.toLowerCase().contains('price')) {
                  final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
                  final parsed = double.tryParse(cleaned);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                }
                return null;
              }
            : null,
        decoration: _inputDecoration(label).copyWith(hintText: hint),
      ),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    hintStyle: TextStyle(
      color: AppColors.textSecondary.withValues(alpha: 0.65),
      fontSize: 13,
    ),
    filled: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}
