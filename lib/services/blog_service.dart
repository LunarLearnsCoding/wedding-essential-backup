import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/blog_model.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // BLOGS

  Stream<List<BlogModel>> getAllBlogs() {
    return _firestore
        .collection(FirestoreCollections.blogs)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BlogModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  Stream<List<BlogModel>> getPublishedBlogs() {
    return getAllBlogs().map(
      (blogs) => blogs.where((blog) => blog.isPublished).toList(),
    );
  }
}
