import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/service_model.dart';

class ServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addService(ServiceModel service) async {
    await _firestore
        .collection(FirestoreCollections.services)
        .add(service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    await _firestore
        .collection(FirestoreCollections.services)
        .doc(service.id)
        .update(service.toMap());
  }

  Future<void> deleteService(String serviceId) async {
    final serviceReference = _firestore
        .collection(FirestoreCollections.services)
        .doc(serviceId);
    final bookings = await _firestore
        .collection(FirestoreCollections.bookings)
        .where('serviceId', isEqualTo: serviceId)
        .get();

    final references = bookings.docs
        .where(
          (doc) =>
              (doc.data()['status'] ?? '').toString().toLowerCase() !=
              'completed',
        )
        .map((doc) => doc.reference)
        .toList();
    var offset = 0;
    var serviceDeleted = false;
    while (offset < references.length) {
      final batch = _firestore.batch();
      final end = (offset + 499).clamp(0, references.length);
      if (!serviceDeleted) {
        batch.delete(serviceReference);
        serviceDeleted = true;
      }
      for (final reference in references.sublist(offset, end)) {
        batch.delete(reference);
      }
      await batch.commit();
      offset = end;
    }

    if (!serviceDeleted) {
      await serviceReference.delete();
    }
  }

  Future<void> updateServiceStatus(String serviceId, bool isActive) async {
    await _firestore
        .collection(FirestoreCollections.services)
        .doc(serviceId)
        .update({
          'isActive': isActive,
          'status': isActive ? 'active' : 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<ServiceModel>> getAllActiveServices() {
    return _firestore
        .collection(FirestoreCollections.services)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ServiceModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<ServiceModel>> getServicesByVendor(String vendorId) {
    return _firestore
        .collection(FirestoreCollections.services)
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ServiceModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<ServiceModel>> getServicesByCategory(String category) {
    return _firestore
        .collection(FirestoreCollections.services)
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ServiceModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<ServiceModel>> filterServices({
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreCollections.services)
        .where('isActive', isEqualTo: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }

    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
