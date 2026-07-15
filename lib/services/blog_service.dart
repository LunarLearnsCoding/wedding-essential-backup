import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../models/blog_model.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // BLOGS

  Future<void> addBlog(BlogModel blog) async {
    await _firestore.collection(FirestoreCollections.blogs).add(blog.toMap());
  }

  Future<void> updateBlog(BlogModel blog) async {
    await _firestore
        .collection(FirestoreCollections.blogs)
        .doc(blog.id)
        .update(blog.toMap());
  }

  Future<void> deleteBlog(String blogId) async {
    await _firestore
        .collection(FirestoreCollections.blogs)
        .doc(blogId)
        .delete();
  }

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

  Future<BlogModel?> getBlogById(String blogId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.blogs)
        .doc(blogId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return BlogModel.fromMap(doc.id, doc.data()!);
  }

  // COMMENTS

  Future<void> addComment(BlogCommentModel comment) async {
    await _firestore
        .collection(FirestoreCollections.blogComments)
        .add(comment.toMap());
  }

  Future<void> deleteComment(String commentId) async {
    await _firestore
        .collection(FirestoreCollections.blogComments)
        .doc(commentId)
        .delete();
  }

  Stream<List<BlogCommentModel>> getCommentsByBlog(String blogId) {
    return _firestore
        .collection(FirestoreCollections.blogComments)
        .where('blogId', isEqualTo: blogId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BlogCommentModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
