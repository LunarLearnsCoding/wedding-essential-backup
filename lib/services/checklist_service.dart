import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/checklist_task_model.dart';

class ChecklistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTask(ChecklistTaskModel task) async {
    await _firestore
        .collection(FirestoreCollections.checklistTasks)
        .add(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection(FirestoreCollections.checklistTasks)
        .doc(taskId)
        .delete();
  }

  Future<void> toggleTask({
    required String taskId,
    required bool isCompleted,
  }) async {
    await _firestore
        .collection(FirestoreCollections.checklistTasks)
        .doc(taskId)
        .update({'isCompleted': isCompleted, 'updatedAt': Timestamp.now()});
  }

  Stream<List<ChecklistTaskModel>> getTasksByCustomer(String customerId) {
    return _firestore
        .collection(FirestoreCollections.checklistTasks)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChecklistTaskModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
