import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/service_model.dart';
import '../../services/service_service.dart';
import '../../core/widgets/vendor_bottom_nav.dart';
import 'vendor_service_form_screen.dart';

class VendorServicesScreen extends StatelessWidget {
  const VendorServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final serviceService = ServiceService();

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendorServiceFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: serviceService.getServicesByVendor(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return const Center(child: Text('No services added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];

              return _ServiceCard(
                service: service,
                onToggleStatus: () async {
                  await serviceService.updateServiceStatus(
                    service.id,
                    !service.isActive,
                  );
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete Service'),
                        content: const Text(
                          'Are you sure you want to delete this service?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await serviceService.deleteService(service.id);
                  }
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 1),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 6),

            Text(service.category, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 8),

            Text(service.description),

            const SizedBox(height: 8),

            Text('Location: ${service.location}'),

            const SizedBox(height: 6),

            Text(
              'Rs. ${service.price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Chip(
                  label: Text(service.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: service.isActive
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                ),

                const Spacer(),

                TextButton(
                  onPressed: onToggleStatus,
                  child: Text(service.isActive ? 'Hide' : 'Activate'),
                ),

                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
