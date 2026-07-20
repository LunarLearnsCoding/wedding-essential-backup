import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/firestore_parsers.dart';

class BlogModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String authorId;
  final String authorName;
  final String category;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.authorId,
    required this.authorName,
    this.category = 'Planning',
    this.status = 'draft',
    required this.createdAt,
    this.updatedAt,
  });

  factory BlogModel.fromMap(String id, Map<String, dynamic> map) {
    return BlogModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? map['author'] ?? 'Admin',
      category: map['category']?.toString() ?? 'Planning',
      status: map['status']?.toString() ?? 'draft',
      createdAt: dateTimeFromFirestoreOrNow(map['createdAt']),
      updatedAt: dateTimeFromFirestore(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  bool get isPublished => status.toLowerCase().trim() == 'published';

  String get summary {
    final normalized = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 150) return normalized;
    return '${normalized.substring(0, 147).trimRight()}...';
  }
}
