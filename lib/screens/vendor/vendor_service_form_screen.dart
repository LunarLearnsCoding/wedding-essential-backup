import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';

class VendorServiceFormScreen extends StatefulWidget {
  const VendorServiceFormScreen({super.key});

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
  final _priceUnitController = TextEditingController(text: 'per day');
  final _descriptionController = TextEditingController();

  String _status = 'Active';
  bool _isSaving = false;

  final List<_PackageDraft> _packages = [
    _PackageDraft(
      name: TextEditingController(text: 'Basic'),
      price: TextEditingController(),
      features: [TextEditingController(text: 'Up to 100 guests')],
    ),
  ];

  @override
  void dispose() {
    _serviceNameController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _priceUnitController.dispose();
    _descriptionController.dispose();

    for (final package in _packages) {
      package.dispose();
    }

    super.dispose();
  }

  void _addPackage() {
    setState(() {
      _packages.add(
        _PackageDraft(
          name: TextEditingController(),
          price: TextEditingController(),
          features: [TextEditingController()],
        ),
      );
    });
  }

  void _removePackage(int index) {
    if (_packages.length == 1) return;

    final removedPackage = _packages.removeAt(index);
    removedPackage.dispose();

    setState(() {});
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to add a service.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(currentUser.uid)
          .get();

      final vendorData = vendorDoc.data() ?? {};
      final vendorName =
          vendorData['businessName']?.toString().trim().isNotEmpty == true
          ? vendorData['businessName'].toString().trim()
          : (vendorData['name']?.toString().trim().isNotEmpty == true
                ? vendorData['name'].toString().trim()
                : currentUser.email ?? 'Vendor');

      final service = ServiceModel(
        id: '',
        vendorId: currentUser.uid,
        vendorName: vendorName,
        name: _serviceNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        location: _locationController.text.trim(),
        price: _parsePrice(_priceController.text),
        imageUrls: const [],
        averageRating: 0,
        totalReviews: 0,
        isActive: _status == 'Active',
        createdAt: DateTime.now(),
      );

      await ServiceService().addService(service);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service published successfully.')),
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
          const _ServiceFormHeader(),

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

                        Row(
                          children: [
                            Expanded(
                              child: _TextInput(
                                label: 'Starting Price',
                                hint: 'Rs. 50,000',
                                controller: _priceController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TextInput(
                                label: 'Price Unit',
                                hint: 'per day',
                                controller: _priceUnitController,
                              ),
                            ),
                          ],
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

                    const SizedBox(height: 18),

                    _FormCard(
                      title: 'Packages',
                      trailing: TextButton.icon(
                        onPressed: _addPackage,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      children: [
                        ..._packages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final package = entry.value;

                          return _PackageEditor(
                            index: index,
                            package: package,
                            canRemove: _packages.length > 1,
                            onRemove: () {
                              _removePackage(index);
                            },
                            onChanged: () {
                              setState(() {});
                            },
                          );
                        }),
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
                          _isSaving ? 'Publishing...' : 'Publish Service',
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
  const _ServiceFormHeader();

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

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vendor Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Add Service',
                  style: TextStyle(
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
  final Widget? trailing;

  const _FormCard({required this.title, required this.children, this.trailing});

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
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

class _PackageEditor extends StatelessWidget {
  final int index;
  final _PackageDraft package;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PackageEditor({
    required this.index,
    required this.package,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Package ${index + 1}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _TextInput(
                  label: 'Package Name',
                  hint: 'Basic',
                  controller: package.name,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TextInput(
                  label: 'Price',
                  hint: 'Rs. 50,000',
                  controller: package.price,
                ),
              ),
            ],
          ),

          const Text(
            'Features Included',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          ...package.features.asMap().entries.map((entry) {
            final featureIndex = entry.key;
            final controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      decoration: _inputDecoration(
                        'Feature ${featureIndex + 1}',
                      ).copyWith(hintText: 'Example: 6 hours coverage'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    onPressed: package.features.length == 1
                        ? null
                        : () {
                            final removedFeature = package.features.removeAt(
                              featureIndex,
                            );
                            removedFeature.dispose();
                            onChanged();
                          },
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }),

          TextButton.icon(
            onPressed: () {
              package.features.add(TextEditingController());
              onChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Feature'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
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

class _PackageDraft {
  final TextEditingController name;
  final TextEditingController price;
  final List<TextEditingController> features;

  _PackageDraft({
    required this.name,
    required this.price,
    required this.features,
  });

  void dispose() {
    name.dispose();
    price.dispose();

    for (final feature in features) {
      feature.dispose();
    }
  }
}
