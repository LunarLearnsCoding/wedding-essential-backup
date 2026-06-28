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
    await _firestore
        .collection(FirestoreCollections.services)
        .doc(serviceId)
        .delete();
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

  Future<ServiceModel?> getServiceById(String serviceId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.services)
        .doc(serviceId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ServiceModel.fromMap(doc.id, doc.data()!);
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