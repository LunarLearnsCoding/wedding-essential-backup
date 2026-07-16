import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';

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

  bool get _isUpdateMode => widget.service != null;

  @override
  void initState() {
    super.initState();

    final service = widget.service;
    if (service == null) return;

    _serviceNameController.text = service.name;
    _categoryController.text = service.category;
    _locationController.text = service.location;
    _priceController.text = service.price.toStringAsFixed(0);
    _descriptionController.text = service.description;
    _status = service.isActive ? 'Active' : 'Paused';
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
      late final String vendorId;
      late final String vendorName;

      if (existingService == null) {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(currentUser.uid)
            .get();

        final vendorData = vendorDoc.data() ?? {};
        vendorId = currentUser.uid;
        vendorName =
            vendorData['businessName']?.toString().trim().isNotEmpty == true
            ? vendorData['businessName'].toString().trim()
            : (vendorData['name']?.toString().trim().isNotEmpty == true
                  ? vendorData['name'].toString().trim()
                  : currentUser.email ?? 'Vendor');
      } else {
        vendorId = existingService.vendorId;
        vendorName = existingService.vendorName;
      }

      final service = ServiceModel(
        id: existingService?.id ?? '',
        vendorId: vendorId,
        vendorName: vendorName,
        name: _serviceNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        location: _locationController.text.trim(),
        price: _parsePrice(_priceController.text),
        imageUrls: existingService?.imageUrls ?? const [],
        averageRating: existingService?.averageRating ?? 0,
        totalReviews: existingService?.totalReviews ?? 0,
        isActive: _status == 'Active',
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

                        _TextInput(
                          label: 'Category',
                          hint: 'Photography, Venue, Makeup...',
                          controller: _categoryController,
                        ),

                        _TextInput(
                          label: 'Location',
                          hint: 'Kathmandu, Lalitpur, Pokhara...',
                          controller: _locationController,
                        ),

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
